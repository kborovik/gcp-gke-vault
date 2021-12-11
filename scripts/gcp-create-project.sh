#!/usr/bin/env bash

# shellcheck disable=SC1091
# shellcheck disable=SC2086

set -e

gcp_project_id=${1}
gcp_organization_id=${2}
gcp_billing_account_id=${3}
gcp_region=${4:-"us-central1"}

export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

_usage() {
  echo -e "\nUsage: $(basename "$0") <google_project> <google_organization_id> <google_billing_account_id> <google_region>"
  exit 1
}

[[ -z "${gcp_project_id}" || -z "${gcp_organization_id}" || -z "${gcp_billing_account_id}" || -z "${gcp_region}" ]] && _usage

if ! gcloud projects describe --format='value(projectId)' "${gcp_project_id}"; then
  gcloud projects create "${gcp_project_id}" --organization="${gcp_organization_id}"
fi

gcloud config set project "${gcp_project_id}"

gcloud beta billing projects link "${gcp_project_id}" --billing-account "${gcp_billing_account_id}"

if ! gsutil ls gs://terraform-"${gcp_project_id}"; then
  gsutil mb -p "${gcp_project_id}" -c "Standard" -l "${gcp_region}" -b on --pap "enforced" gs://terraform-"${gcp_project_id}"
fi

gcloud services enable cloudresourcemanager.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable container.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable dns.googleapis.com
gcloud services enable osconfig.googleapis.com
