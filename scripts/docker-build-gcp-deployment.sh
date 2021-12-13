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
_get_terraform_gcp_output ${google_project}

google_region=$(jq -r ".google_region.value // empty" "${terraform_gcp_output:?}")
root_ca_certificate_url=$(jq -r ".root_ca_certificate_url.value // empty" "${terraform_gcp_output:?}")
docker_tag="${google_region:?}-docker.pkg.dev/${google_project}/containers/gcp-deployment"
revision="$(date -I)"

gcloud auth configure-docker "${google_region:?}-docker.pkg.dev"

docker build \
  --tag="${docker_tag:?}:${revision}" \
  --tag="${docker_tag:?}:latest" \
  --build-arg=ROOT_CA_CERTIFICATE_URL=${root_ca_certificate_url:?} \
  --file="containers/gcp-deployment/Dockerfile" "containers/gcp-deployment/"

docker push "${docker_tag}:${revision}"
docker push "${docker_tag}:latest"
docker rmi "${docker_tag}:${revision}" "${docker_tag}:latest"
