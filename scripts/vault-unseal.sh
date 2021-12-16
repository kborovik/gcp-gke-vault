#!/usr/bin/env bash

# shellcheck disable=SC1091
# shellcheck disable=SC2086

#
# Vault Installation to Google Kubernetes Engine via Helm
# https://learn.hashicorp.com/tutorials/vault/kubernetes-google-cloud-gke?in=vault/kubernetes
#

_remove_cluster_keys() {
  if [[ -f "${vault_cluster_keys}" ]]; then
    shred -vuf "${vault_cluster_keys}"
  fi
}

_exit_scripts() {
  _remove_temp_files
  _remove_cluster_keys
}

trap _exit_scripts EXIT

_usage() {
  echo -e "\n Usage: $(basename ${0})"
  echo -e "\t -p <google_project>   - GCP Project ID (required)"
  echo -e "\t -n <vault_dns_name>   - Vault GKE DNS Name (required)"
  echo -e "\t -g <google_gke_name>  - GKE cluster name (optional)"
  echo -e "\n Example:"
  echo -e "\t $(basename ${0}) -p <google_project> -n <vault_dns_name>"
  exit 1
}

while getopts "n:p:g" option; do
  case ${option} in
  n)
    vault_dns_name=${OPTARG}
    ;;
  p)
    google_project=${OPTARG}
    ;;
  g)
    google_gke_name=${OPTARG}
    ;;
  *)
    _usage
    ;;
  esac
done

if [[ -z "${vault_dns_name}" || -z ${google_project} ]]; then
  _usage
fi

_validate_google_project_name ${google_project}
_get_terraform_gcp_output ${google_project}
_validate_vault_dns_name ${vault_dns_name}

vault_cluster_keys="${HOME}/vault-cluster-keys.json"
vault_secret=$(gcloud secrets list --format="value(name)" --filter="${vault_dns_name}-vault-key")
google_region="$(jq -r ".google_region.value // empty" ${terraform_gcp_output:?})"
google_gke_name=${google_gke_name:-$(jq -r ".gke_names.value[0]" ${terraform_gcp_output:?})}

gcloud container clusters get-credentials "${google_gke_name:?}" --region="${google_region:?}"

kubectl --namespace="${vault_dns_name}" get pods

secret_version=$(gcloud secrets versions list "${vault_secret}" --sort-by=name --limit=1 --format="value(name)")
vault_key=$(gcloud secrets versions access --secret="${vault_secret}" "${secret_version:?}")
vault_unseal_keys=$(echo ${vault_key:?} | jq -r ".recovery_keys_b64[] // empty")
VAULT_TOKEN=$(echo ${vault_key} | jq -r ".root_token // empty")

for pod in 0 1 2; do
  for unseal_key in ${vault_unseal_keys}; do
    if [[ $(kubectl -n "${vault_dns_name}" exec "${vault_dns_name}-${pod}" -- vault status -format json | jq -r ".sealed") == false ]]; then
      break
    fi
    kubectl --namespace="${vault_dns_name}" exec "${vault_dns_name}-${pod}" -- vault operator unseal "${unseal_key}"
  done
done

echo -e "\n\nVault Status\n"
kubectl --namespace="${vault_dns_name}" exec "${vault_dns_name}-0" -- vault status
kubectl --namespace="${vault_dns_name}" exec "${vault_dns_name}-0" -- vault login -no-print "${VAULT_TOKEN:?}"
kubectl --namespace="${vault_dns_name}" exec "${vault_dns_name}-0" -- vault operator raft list-peers
