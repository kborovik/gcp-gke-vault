#!/usr/bin/env bash

#
# Vault Terraform state file is encrypted with Customer Managed Key (CMK)
# Generate CMK:
# > openssl rand -base64 -out cmk.key 32
# > gcloud secrets versions add --data-file cmk.key vault_dns_name-terraform-state-key
#

# shellcheck disable=SC1091
# shellcheck disable=SC2086

source "scripts/lib-functions.sh"

_usage() {
  echo -e "\n Usage: $(basename ${0})"
  echo -e "\t -p <google_project>   - GCP Project ID (required)"
  echo -e "\t -n <vault_dns_name>   - Vault GKE DNS Name (required)"
  echo -e "\t -a                    - Apply Terraform scripts (optional)"
  echo -e "\t -l                    - Show Terraform state (optional)"
  echo -e "\n Example:"
  echo -e "\n Terraform plan:\n\t $(basename $0) -p <google_project> -n <vault_dns_name>"
  echo -e "\n Terraform apply:\n\t $(basename $0) -p <google_project> -n <vault_dns_name> -a"
  echo -e "\n Terraform show:\n\t $(basename $0) -p <google_project> -n <vault_dns_name> -l"
  exit 1
}

while getopts "n:p:al" option; do
  case ${option} in
  n)
    vault_dns_name=${OPTARG}
    ;;
  p)
    google_project=${OPTARG}
    ;;
  a)
    terraform="apply"
    ;;
  l)
    terraform="show"
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

domain_name=$(jq -r ".dns_zone.value // empty" ${terraform_gcp_output:?} | sed 's/.$//')
fqdn="${vault_dns_name}.${domain_name:?}"
export VAULT_ADDR="https://${fqdn}:8200"

secret_version=$(gcloud secrets versions list "${vault_dns_name}-vault-key" --sort-by=name --limit=1 --format="value(name)")
VAULT_TOKEN=$(gcloud secrets versions access --secret="${vault_dns_name}-vault-key" "${secret_version:?}" | jq -r ".root_token")

secret_version=$(gcloud secrets versions list "${vault_dns_name}-terraform-state-key" --sort-by=name --limit=1 --format="value(name)")
terraform_state_encryption_key=$(gcloud secrets versions access --secret="${vault_dns_name}-terraform-state-key" "${secret_version:?}")

export TF_VAR_vault_dns_name=${vault_dns_name}
export GOOGLE_PROJECT=${google_project}
export VAULT_CLIENT_TIMEOUT="10"
export VAULT_MAX_RETRIES="30"
export VAULT_ADDR
export VAULT_TOKEN

cd terraform/vault || exit

_validate_terraform_fmt

terraform init -upgrade -input=false -reconfigure \
  -backend-config="bucket=terraform-${google_project}" \
  -backend-config="prefix=terraform-state/gcp/vault/${vault_dns_name}" \
  -backend-config="encryption_key=${terraform_state_encryption_key:?}"

terraform validate

_connect_gke_proxy

if [[ ${terraform} == "apply" ]]; then

  terraform apply -auto-approve -input=false -refresh=true
  terraform output -json -no-color >output.json
  _disconnect_gke_proxy
  gsutil cp "file://output.json" "gs://terraform-${google_project}/terraform-state/gcp/vault/${vault_dns_name}"

elif [[ ${terraform} == "show" ]]; then
  terraform show
else
  terraform plan -input=false -refresh=true
fi
