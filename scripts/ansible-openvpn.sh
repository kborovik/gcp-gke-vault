#!/usr/bin/env bash

# shellcheck disable=SC1091
# shellcheck disable=SC2086

#
# OpenVPN Access Server Ansible deployment
# https://openvpn.net/vpn-software-packages/
#

# TODO: dynamically assign IP routes based on terraform output

source "scripts/lib-functions.sh"

_exit_scripts() {
  _remove_temp_files
  if [[ -f ${ansible_gcp_inventory} ]]; then
    rm -rf ${ansible_gcp_inventory}
  fi
  if [[ -f ${ansible_ssh_key} ]]; then
    shred -uf ${ansible_ssh_key}
  fi
}

trap _exit_scripts EXIT

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

export ANSIBLE_HOST_KEY_CHECKING=false

ansible_gcp_inventory="${HOME}/hosts-${google_project}.yaml"
ansible_ssh_key="${HOME}/ansible-cloudbuild-ssh.key"
ansible_openvpn_hostname=$(jq -r ".external_ip_vpn.value // empty" "${terraform_gcp_output:?}")

# create Ansible inventory for specific gcp_project_id
sed -e "s/ANSIBLE_OPENVPN_HOSTNAME/${ansible_openvpn_hostname:?}/g" "ansible/inventory/hosts.yaml" >"${ansible_gcp_inventory}"

# fetch Ansible SSH key
secret_version=$(gcloud secrets versions list cloudbuild-ssh-key --sort-by=name --limit=1 --format="value(name)")
gcloud secrets versions access --secret="cloudbuild-ssh-key" "${secret_version:?}" >"${ansible_ssh_key}"
chmod 0600 "${ansible_ssh_key}"

# run Ansible playbook
ansible-playbook "ansible/playbooks/openvpn.yaml" \
  --private-key "${ansible_ssh_key}" \
  --inventory "${ansible_gcp_inventory}" \
  --extra-vars openvpn_hostname="${ansible_openvpn_hostname}"
