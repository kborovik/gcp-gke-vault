#!/usr/bin/env bash

# shellcheck disable=SC1091
# shellcheck disable=SC2086

set -o errexit

export PS4='+(${BASH_SOURCE}:${LINENO}):[$?] ${FUNCNAME[0]:+${FUNCNAME[0]}[$?]: }'
export terraform_gcp_output="${HOME}/terraform-gcp-output.json"
export terraform_vault_output="${HOME}/terraform-vault-output.json"
export cloudbuild_ssh_key="${HOME}/cloudbuild-ssh.key"

_print_header() {
  echo -e "\n=========================================================================================================="
  echo -e "${@}"
  echo -e "=========================================================================================================="
}

_validate_google_project_name() {
  if [[ -z ${1} ]]; then
    echo -e "Usage: ${FUNCNAME[0]} <google_project>"
    exit 1
  fi
  mapfile -t -d ' ' available_google_projects < <(gcloud projects list --format="value(project_id)" | tr '\n' ' ')
  if [ "${1}" == "$(compgen -W "${available_google_projects[*]}" "${1}" | head -1)" ]; then
    return 0
  else
    echo -e "\nAvailable Google projects: ${available_google_projects[*]}"
    exit 1
  fi
}

_validate_vault_dns_name() {
  if [[ -z ${1} ]]; then
    echo -e "Usage: ${FUNCNAME[0]} <vault_dns_names>"
    exit 1
  fi
  mapfile -t -d ' ' available_vault_dns_names < <(jq -r ".vault_dns_records.value[] | .name // empty" ${terraform_gcp_output:?} | tr '\n' ' ')
  if [ "${1}" == "$(compgen -W "${available_vault_dns_names[*]}" "${1}" | head -1)" ]; then
    return 0
  else
    echo -e "\nAvailable Vault DNS names: ${available_vault_dns_names[*]}"
    exit 1
  fi
}

_validate_vault_approle_name() {
  if [[ -z ${1} ]]; then
    echo -e "Usage: ${FUNCNAME[0]} <vault_approle_names>"
    exit 1
  fi
  mapfile -t -d ' ' available_vault_approle_names < <(jq -r ".approle.value[].role_name // empty" ${terraform_vault_output:?} | tr '\n' ' ')
  if [ "${1}" == "$(compgen -W "${available_vault_approle_names[*]:?}" "${1}" | head -1)" ]; then
    return 0
  else
    echo -e "\nAvailable Vault AppRole names: ${available_vault_approle_names[*]}"
    exit 1
  fi
}

_validate_terraform_fmt() {
  if ! terraform fmt -check; then
    echo -e "Format Terraform files according to the standard: https://www.terraform.io/docs/cli/commands/fmt.html"
    exit 1
  fi
}

_get_terraform_gcp_output() {
  if [[ -z ${1} ]]; then
    echo -e "Usage: ${FUNCNAME[0]} <google_project>"
    exit 1
  fi
  local google_project=${1}
  if ! gsutil cp "gs://terraform-${google_project}/terraform-state/gcp/output.json" ${terraform_gcp_output} &>/dev/null; then
    echo -e "\nUnable to copy gs://terraform-${google_project}/terraform-state/gcp/output.json to local disk.\n"
  fi
}

_get_terraform_vault_output() {
  if [[ -z ${1} || -z ${2} ]]; then
    echo -e "Usage: ${FUNCNAME[0]} <google_project> <vault_dns_name>"
    exit 1
  fi
  local google_project=${1}
  local vault_dns_name=${2}
  if ! gsutil cp "gs://terraform-${google_project}/terraform-state/gcp/vault/${vault_dns_name}/output.json" "${terraform_vault_output}" &>/dev/null; then
    echo -e "\nUnable to copy gs://terraform-${google_project}/terraform-state/gcp/vault/${vault_dns_name}/output.json to local disk.\n"
  fi
}

#
# This function automates gcloud config profile activation. Helps to eliminate google_project switching errors.
# This function requires manual creation of gcloud config profile named after the target google_project
#
_activate_gcloud_profile() {
  if [[ -z ${1} ]]; then
    echo -e "Usage: ${FUNCNAME[0]} <google_project>"
    exit 1
  fi
  local google_project=${1}
  mapfile -t -d ' ' gcloud_profiles < <(gcloud config configurations list "--format=value(name)" | tr '\n' ' ')
  if [ "${google_project}" == "$(compgen -W "${gcloud_profiles[*]}" "${google_project}" | head -1)" ]; then
    gcloud config configurations activate ${google_project}
  fi
}

#
# Due to private GKE restrictions we have to use SSH SOCKS proxy to connect to GKE back plane
#
_connect_gke_proxy() {

  if [[ -z ${IS_CLOUD_BUILD} ]]; then
    return 0
  fi

  local ssh_key_version
  local gke_proxy_ip_address

  gke_proxy_ip_address=$(jq -r ".internal_ip_gke_proxy.value // empty" ${terraform_gcp_output})

  ssh_key_version=$(gcloud secrets versions list "cloudbuild-ssh-key" --sort-by=name --limit=1 --format="value(name)")
  gcloud secrets versions access --secret="cloudbuild-ssh-key" "${ssh_key_version:?}" >"${cloudbuild_ssh_key}"
  chmod 0600 "${cloudbuild_ssh_key}"

  ssh -f -n -N -D 127.0.0.1:8080 \
    -o StrictHostKeyChecking=no \
    -o ConnectTimeout=5 \
    -o ConnectionAttempts=5 \
    -o ExitOnForwardFailure=yes \
    -i "${cloudbuild_ssh_key}" \
    "cloudbuild@${gke_proxy_ip_address:?}"

  export HTTPS_PROXY="socks5://127.0.0.1:8080"
}

_disconnect_gke_proxy() {
  unset HTTPS_PROXY
  if ! pkill -f "ssh -f -n -N -D 127.0.0.1:8080"; then
    true
  fi
}

_remove_temp_files() {
  if [[ -f ${terraform_gcp_output} ]]; then
    rm -f ${terraform_gcp_output}
  fi
  if [[ -f ${terraform_vault_output} ]]; then
    rm -f ${terraform_vault_output}
  fi
  if [[ -f "${cloudbuild_ssh_key}" ]]; then
    rm -rf "${cloudbuild_ssh_key}"
  fi
}

_default_exit_scripts() {
  _disconnect_gke_proxy
  _remove_temp_files
}

trap _default_exit_scripts EXIT
