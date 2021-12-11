#!/usr/bin/env bash

# shellcheck disable=SC1091
# shellcheck disable=SC2086

google_project="${1}"
google_service_account="${2}"

if [[ -z ${google_project} || -z ${google_service_account} ]]; then
  echo -e "\n Usage: $(basename ${0}) <google_project> <google_service_account> \n"
  exit 1
fi

gcloud projects get-iam-policy \
  --flatten="bindings[].members" \
  --format="table(bindings.role)" \
  --filter="bindings.members=serviceAccount:${google_service_account}" "${google_project}"
