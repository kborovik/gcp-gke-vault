#!/usr/bin/env bash

# shellcheck disable=SC1091
# shellcheck disable=SC2086

source "scripts/lib-functions.sh"

_usage() {
  echo -e "\n Usage: $(basename $0)"
  echo -e "\t -p <google_project>  - GCP Project ID (required)"
  echo -e "\t -n <vault_dns_name>   - Vault GKE DNS Name (required)"
  echo -e "\n Examples:"
  echo -e "\n Run pipeline:\n\t $(basename $0) -p <google_project> -n <vault_dns_name>"
  exit 1
}

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

if [[ -z ${google_project} || -z ${vault_dns_name} ]]; then
  _usage
fi

_validate_google_project_name ${google_project}
_get_terraform_gcp_output ${google_project}
_validate_vault_dns_name ${vault_dns_name}

./scripts/gcp-deploy.sh -p ${google_project} -a

./scripts/vault-deploy.sh -p ${google_project} -n ${vault_dns_name} -a
./scripts/vault-config.sh -p ${google_project} -n ${vault_dns_name} -a

./scripts/vault-test-gke.sh -p ${google_project} -n ${vault_dns_name}

for approle in "test1" "test2"; do
  ./scripts/vault-test-approle.sh -p ${google_project} -n ${vault_dns_name} -r ${approle}
done
