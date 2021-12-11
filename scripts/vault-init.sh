#!/usr/bin/env bash

# shellcheck disable=SC1091
# shellcheck disable=SC2086

#
# Vault Installation to Google Kubernetes Engine via Helm
# https://learn.hashicorp.com/tutorials/vault/kubernetes-google-cloud-gke?in=vault/kubernetes
#

source "scripts/lib-functions.sh"

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
  echo -e "\t -d <vault_dns_name>   - Vault GKE DNS Name (required)"
  echo -e "\t -g <google_gke_name>  - GKE cluster name (optional)"
  echo -e "\n Example:"
  echo -e "\t $(basename ${0}) -p <google_project> -d <vault_dns_name>"
  exit 1
}

while getopts "d:p:g" option; do
  case ${option} in
  d)
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
_get_terraform_output_file ${google_project}
_validate_vault_dns_name ${vault_dns_name}

vault_cluster_keys="${HOME}/vault-cluster-keys.json"
vault_secret=$(gcloud secrets list --format="value(name)" --filter="${vault_dns_name}-vault-key")
google_region="$(jq -r ".google_region.value // empty" ${terraform_output_file:?})"
google_gke_name=${google_gke_name:-$(jq -r ".gke_names.value[0] // empty" ${terraform_output_file:?})}

gcloud container clusters get-credentials "${google_gke_name:?}" --region="${google_region:?}"

kubectl --namespace="${vault_dns_name}" get pods

echo -e "\nInitializing Vault"
kubectl --namespace="${vault_dns_name}" exec "${vault_dns_name}-0" -- vault operator init -key-shares=5 -key-threshold=3 -format=json | tee "${vault_cluster_keys}"

gcloud secrets versions add ${vault_secret:?} --data-file=${vault_cluster_keys}

while [[ $(kubectl -n "${vault_dns_name}" get pods "${vault_dns_name}-0" --output=jsonpath='{.status.containerStatuses[].ready}') == false ]]; do
  echo -e "Waiting for pod ${vault_dns_name}-0 to start..."
  sleep 3
done

secret_version=$(gcloud secrets versions list "${vault_secret}" --sort-by=name --limit=1 --format="value(name)")
vault_key=$(gcloud secrets versions access --secret="${vault_secret}" "${secret_version:?}")
vault_unseal_keys=$(echo ${vault_key:?} | jq -r ".recovery_keys_b64[] // empty")
VAULT_TOKEN=$(echo ${vault_key} | jq -r ".root_token // empty")

for unseal_key in ${vault_unseal_keys:?}; do
  if [[ $(kubectl -n "${vault_dns_name}" exec "${vault_dns_name}-0" -- vault status -format json | jq -r ".sealed") == false ]]; then
    break
  fi
  kubectl --namespace="${vault_dns_name}" exec "${vault_dns_name}-0" -- vault operator unseal "${unseal_key}"
done

kubectl --namespace="${vault_dns_name}" exec "${vault_dns_name}-1" -- vault operator raft join "https://${vault_dns_name}-0.${vault_dns_name}-internal:8200"
kubectl --namespace="${vault_dns_name}" exec "${vault_dns_name}-2" -- vault operator raft join "https://${vault_dns_name}-0.${vault_dns_name}-internal:8200"

for pod in 1 2; do
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
