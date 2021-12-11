#!/usr/bin/env bash

# shellcheck disable=SC1091
# shellcheck disable=SC2086

source "scripts/lib-functions.sh"

_usage() {
  echo -e "\n Usage: $(basename $0)"
  echo -e "\t -p <google_project>  - GCP Project ID (required)"
  echo -e "\n Examples:"
  echo -e "\n Terraform plan:\n\t $(basename $0) -p <google_project>"
  exit 1
}

while getopts "p:" option; do
  case ${option} in
  p)
    google_project=${OPTARG}
    ;;
  *)
    _usage
    ;;
  esac
done

if [[ -z ${google_project} ]]; then
  _usage
fi

_validate_google_project_name ${google_project}
_get_terraform_output_file ${google_project}

google_region=$(jq -r ".google_region.value // empty" "${terraform_output_file:?}")
docker_tag="${google_region:?}-docker.pkg.dev/${google_project}/containers/vault"
vault_version="$(grep -e "^ARG VAULT_VERSION=" containers/vault/Dockerfile | cut -d "=" -f 2)"

gcloud auth configure-docker "${google_region:?}-docker.pkg.dev"

docker build \
  --tag="${docker_tag:?}:${vault_version:?}" \
  --file="containers/vault/Dockerfile" "containers/vault/"

docker push "${docker_tag}:${vault_version}"
docker rmi "${docker_tag}:${vault_version}"
