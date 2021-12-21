#!/usr/bin/env bash

# shellcheck disable=SC1091
# shellcheck disable=SC2086

source "scripts/lib-functions.sh"

# Functions

_usage() {
  echo -e "\n Usage: $(basename $0)"
  echo -e "\t -p <google_project>   - GCP Project ID (required)"
  echo -e "\t -n <vault_dns_name>   - Vault GKE DNS Name (required)"
  echo -e "\n Example:"
  echo -e "\t $(basename $0) -p <google_project> -n <vault_dns_name>"
  exit 1
}

_test_put_eq_get() {
  uuid_get=$(vault kv get -field=uuid "${vault_secret}")
  if [ "${uuid_get}" == "${uuid_put}" ]; then
    echo -e "OK: UUID match"
    echo -e "\t UUID-WRITE: ${uuid_put}"
    echo -e "\t UUID-READ:  ${uuid_get}"
    echo -e
  else
    echo -e "ERROR: UUID does not match"
    echo -e "\t UUID-WRITE: ${uuid_put}"
    echo -e "\t UUID-READ:  ${uuid_get}"
    echo -e
    exit 1
  fi
}

_restart_pods() {

  standby_pods=$(kubectl -n "${vault_dns_name}" get pods --selector="vault-active=false" --output=jsonpath='{.items[*].metadata.name}')
  active_pods=$(kubectl -n "${vault_dns_name}" get pods --selector="vault-active=true" --output=jsonpath='{.items[*].metadata.name}')

  for pod in ${standby_pods:?}; do
    kubectl delete pods --namespace=${vault_dns_name} ${pod}
    local i=0
    while [[ $(kubectl -n "${vault_dns_name}" get statefulsets ${vault_dns_name} --output=jsonpath='{.status.readyReplicas}') != 3 ]]; do
      echo -e "Waiting for pod ${pod} to restart..."
      sleep 5
      i=$((i + 1))
      if ((i > 12)); then
        echo -e "\nERROR: Vault pod restart time exceeded 60 seconds. Exiting...\n"
        exit 1
      fi
    done
  done

  for pod in ${active_pods:?}; do
    kubectl delete pods --namespace=${vault_dns_name} ${pod}
    local i=0
    while [[ $(kubectl -n "${vault_dns_name}" get statefulsets ${vault_dns_name} --output=jsonpath='{.status.readyReplicas}') != 3 ]]; do
      echo -e "Waiting for pod ${pod} to restart..."
      sleep 5
      i=$((i + 1))
      if ((i > 12)); then
        echo -e "\nERROR: Vault pod restart time exceeded 60 seconds. Exiting...\n"
        exit 1
      fi
    done
  done
}

# Main script

while getopts "n:p:" option; do
  case ${option} in
  n)
    vault_dns_name=${OPTARG}
    ;;
  p)
    google_project=${OPTARG}
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

vault_secret="kv/test1"
uuid_put="$(uuidgen)"
uuid_get=""
date="$(date)"

vault_ip_address=$(jq -r ".vault_dns_records.value[] | select(.name==\"${vault_dns_name}\") | .address // empty" ${terraform_gcp_output:?})
domain_name=$(jq -r ".dns_zone.value // empty" ${terraform_gcp_output:?} | sed 's/.$//')

secret_version=$(gcloud secrets versions list "${vault_dns_name}-vault-key" --sort-by=name --limit=1 --format="value(name)")
VAULT_TOKEN=$(gcloud secrets versions access --secret="${vault_dns_name}-vault-key" "${secret_version:?}" | jq -r ".root_token")

export VAULT_TOKEN
export VAULT_ADDR="https://${vault_ip_address:?}:8200"
export VAULT_CLIENT_TIMEOUT="10"
export VAULT_MAX_RETRIES="30"

_connect_gke_proxy

_print_header "Testing IP_ADDRESS access: VAULT_ADDR=https://${vault_ip_address}:8200"
vault status

export VAULT_ADDR="https://${vault_dns_name}.${domain_name:?}:8200"

_print_header "Testing FQDN access: VAULT_ADDR=https://${vault_dns_name}.${domain_name:?}:8200"
vault status

_print_header "Write ${uuid_put} to Vault secret ${vault_secret}"
vault kv put ${vault_secret} uuid="${uuid_put}" date="${date}"

_print_header "Read Vault secret ${vault_secret}"
vault kv get ${vault_secret}

_print_header "Testing if UUID-WRITE == UUID-READ"
_test_put_eq_get

_print_header "List Vault RAFT Peers"
vault operator raft list-peers

_print_header "Restarting Vault Pods"
_restart_pods

_print_header "List Vault RAFT Peers"
vault operator raft list-peers

_print_header "Read Vault secret ${vault_secret}"
vault kv get ${vault_secret}

_print_header "Testing if UUID-WRITE == UUID-READ"
_test_put_eq_get
