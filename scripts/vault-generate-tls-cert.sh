#!/usr/bin/env bash

# shellcheck disable=SC1091
# shellcheck disable=SC2086

source "scripts/lib-functions.sh"

_remove_tls_keys() {
  if [[ -f "${tls_key}" ]]; then
    shred -vuf "${tls_key}"
  fi
  if [[ -f "${tls_crt}" ]]; then
    shred -uf "${tls_crt}"
  fi
}

_exit_scripts() {
  _remove_temp_files
  _remove_tls_keys
}

trap _exit_scripts EXIT

_usage() {
  echo -e "\n Usage: $(basename ${0})"
  echo -e "\t -p <google_project>   - Google Project ID (required)"
  echo -e "\t -n <vault_dns_name>   - Vault GKE DNS Name (required)"
  echo -e "\n Example:"
  echo -e "\t $(basename ${0}) -p <google_project> -n <vault_dns_name>"
  exit 1
}

while getopts "p:n:" option; do
  case ${option} in
  p)
    google_project=${OPTARG}
    ;;
  n)
    vault_dns_name=${OPTARG}
    ;;
  *)
    _usage
    ;;
  esac
done

if [[ -z ${vault_dns_name} || -z ${google_project} ]]; then
  _usage
fi

_validate_google_project_name ${google_project}
_get_terraform_gcp_output ${google_project}
_validate_vault_dns_name ${vault_dns_name}

google_region="$(jq -r ".google_region.value // empty" ${terraform_gcp_output:?})"
dns_domain=$(jq -r ".dns_zone.value // empty" ${terraform_gcp_output:?} | sed 's/.$//')
vault_ip_address=$(jq -r ".vault_dns_records.value[] | select(.name==\"${vault_dns_name}\") | .address // empty" ${terraform_gcp_output:?})
gcp_ca_pool="$(jq -r ".ca_pool_name.value // empty" ${terraform_gcp_output:?})"
tls_key="${HOME}/${vault_dns_name}.key"
tls_crt="${HOME}/${vault_dns_name}.crt"

# Including the Pyca cryptography library: https://cloud.google.com/kms/docs/crypto
export CLOUDSDK_PYTHON_SITEPACKAGES=1

gcloud privateca certificates create \
  --generate-key \
  --project="${google_project}" \
  --issuer-pool="${gcp_ca_pool:?}" \
  --issuer-location="${google_region:?}" \
  --validity="P365D" \
  --use-preset-profile=leaf_mtls \
  --key-output-file="${tls_key}" \
  --cert-output-file="${tls_crt}" \
  --subject="CN=HashiCorp Vault (${google_project})" \
  --dns-san="${vault_dns_name}.${dns_domain:?}, ${vault_dns_name}-0.vault-cluster, ${vault_dns_name}-1.vault-cluster, ${vault_dns_name}-2.vault-cluster" \
  --ip-san="${vault_ip_address:?}, 127.0.0.1"

gcloud secrets versions add "${vault_dns_name}-tls-key" \
  --project="${google_project}" \
  --data-file="${tls_key}"

gcloud secrets versions add "${vault_dns_name}-tls-crt" \
  --project="${google_project}" \
  --data-file="${tls_crt}"
