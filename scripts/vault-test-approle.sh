#!/usr/bin/env bash

# shellcheck disable=SC1091
# shellcheck disable=SC2086

source "scripts/lib-functions.sh"

_usage() {
  echo -e "\n Usage: $(basename $0)"
  echo -e "\t -p <google_project>   - GCP Project ID (required)"
  echo -e "\t -n <vault_dns_name>   - Vault GKE DNS Name (required)"
  echo -e "\t -r <approle_name>     - Vault AppRole Name (required)"
  echo -e "\n Example:"
  echo -e "\t $(basename $0) -p <google_project> -n <vault_dns_name> -r <approle_name>"
  exit 1
}

while getopts "n:p:r:" option; do
  case ${option} in
  n)
    vault_dns_name=${OPTARG}
    ;;
  p)
    google_project=${OPTARG}
    ;;
  r)
    approle_name=${OPTARG}
    ;;
  *)
    _usage
    ;;
  esac
done

if [[ -z "${vault_dns_name}" || -z ${google_project} || -z ${approle_name} ]]; then
  _usage
fi

_validate_google_project_name ${google_project}
_get_terraform_gcp_output ${google_project}

_validate_vault_dns_name ${vault_dns_name}
_get_terraform_vault_output ${google_project} ${vault_dns_name}

_validate_vault_approle_name ${approle_name}

domain_name=$(jq -r ".dns_zone.value // empty" ${terraform_gcp_output:?} | sed 's/.$//')
export VAULT_ADDR="https://${vault_dns_name}.${domain_name:?}:8200"

role_id=$(jq -r ".approle.value[] | select(.role_name==\"${approle_name}\") .role_id // empty" ${terraform_vault_output:?})
google_secret_name=$(jq -r ".approle.value[] | select(.role_name==\"${approle_name}\") .google_secret_name // empty" ${terraform_vault_output:?})
secret_version=$(gcloud secrets versions list "${google_secret_name:?}" --sort-by=name --limit=1 --format="value(name)")
secret_id=$(gcloud secrets versions access --secret="${google_secret_name:?}" "${secret_version:?}")

_connect_gke_proxy

export VAULT_CLIENT_TIMEOUT="10"
export VAULT_MAX_RETRIES="30"

VAULT_TOKEN=$(vault write auth/approle/login role_id=${role_id:?} secret_id=${secret_id:?} -format=json | jq -r ".auth.client_token // empty")
export VAULT_TOKEN

token_display_name=$(vault token lookup -format=json | jq -r ".data.meta | .role_name // empty")
_print_header "Login as AppRole: ${token_display_name:?}"
vault token lookup

test_data="1234567890"
transit_path="transit"
transit_keys=$(vault list -format=json ${transit_path}/keys | jq -r ".[] // empty" | tr "\n" " ")

_print_header "Testing access: ${transit_path}"

for transit_key in ${transit_keys:?}; do

  if vault write "${transit_path}/encrypt/${transit_key}" plaintext="$(base64 <<<${test_data:?})" &>/dev/null; then
    test_data_ciphertext=$(vault write "${transit_path}/encrypt/${transit_key}" -format=json plaintext="$(base64 <<<${test_data:?})" | jq -r ".data.ciphertext // empty")
    printf "%-8s %-20s %-10s\n" "encrypt" "${transit_path}/${transit_key}" "Allowed"
  else
    printf "%-8s %-20s %-10s\n" "encrypt" "${transit_path}/${transit_key}" "Denied"
    test_data_ciphertext="vault:v1:efS0bDRFHD+9qv3z+G4oLxEoh0pjsAmEgEn+U1rg3MYYhDkjBS8="
  fi

  if vault write "${transit_path}/decrypt/${transit_key}" ciphertext="${test_data_ciphertext:?}" &>/dev/null; then
    printf "%-8s %-20s %-10s\n" "decrypt" "${transit_path}/${transit_key}" "Allowed"
  else
    printf "%-8s %-20s %-10s\n" "decrypt" "${transit_path}/${transit_key}" "Denied"
  fi

done
