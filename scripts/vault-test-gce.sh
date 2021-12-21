#!/usr/bin/env bash

# shellcheck disable=SC1091
# shellcheck disable=SC2086

#
# Vault GCE Login
# https://www.vaultproject.io/docs/auth/gcp#gce-login
#

set -e

export PS4='+(${BASH_SOURCE}:${LINENO})[$?]: ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

_print_header() {
  echo -e "\n=========================================================================================================="
  echo -e "${@}"
  echo -e "==========================================================================================================\n"
}

_trap_jwt_token_errors() {
  if [[ ${?} == 6 ]]; then
    echo -e "\nUnable to get GCE_JWT token. Is this a GCP instance?"
    exit 6
  fi
}

trap _trap_jwt_token_errors ERR

vault_ip_address=${1}
vault_gcp_roles=(gce-test-sa gce-test-label)
uuid_put="$(uuidgen)"
date="$(date)"

if [[ ! "${vault_ip_address}" =~ ^(([01]?[0-9]?[0-9]|2[0-5][0-5])\.){3}([01]?[0-9]?[0-9]|2[0-5][0-5])$ ]]; then
  echo -e "\nUsage: $(basename "$0") vault_ip_address \n"
  exit 1
fi

export VAULT_ADDR="https://${vault_ip_address:?}:8200"

for vault_gcp_role in "${vault_gcp_roles[@]}"; do

  gce_jwt=$(curl --silent --get --header "Metadata-Flavor: Google" \
    --data-urlencode "audience=vault/${vault_gcp_role}" \
    --data-urlencode "format=full" \
    http://metadata/computeMetadata/v1/instance/service-accounts/default/identity)

  VAULT_TOKEN=$(vault write -field=token "auth/gcp/login" role="${vault_gcp_role}" jwt="${gce_jwt:?}")
  export VAULT_TOKEN
  export VAULT_CLIENT_TIMEOUT="10"
  export VAULT_MAX_RETRIES="30"

  vault_secret="kv/${vault_gcp_role}"

  _print_header "Vault Token: ${vault_gcp_role}"
  vault token lookup

  _print_header "Write: ${vault_secret}"
  vault kv put ${vault_secret} uuid="${uuid_put}" date="${date}"

  _print_header "Read: ${vault_secret}"
  vault kv get ${vault_secret}

done
