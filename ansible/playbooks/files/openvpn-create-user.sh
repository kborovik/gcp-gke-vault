#!/usr/bin/env bash

set -e

openvpn_user_name=${1}
openvpn_auth_file="${HOME}"/"${openvpn_user_name}".ovpn

export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

_usage() {
  echo
  echo "Usage: $(basename "$0") <openvpn_user_name>"
  echo
  exit 1
}

[[ -z "${openvpn_user_name}" ]] && _usage

sudo /usr/local/openvpn_as/scripts/sacli --user "${openvpn_user_name}" AutoGenerateOnBehalfOf
sudo /usr/local/openvpn_as/scripts/sacli --user "${openvpn_user_name}" RemoveLocalPassword
sudo /usr/local/openvpn_as/scripts/sacli --user "${openvpn_user_name}" --key "type" --value "user_connect" UserPropPut
sudo /usr/local/openvpn_as/scripts/sacli --user "${openvpn_user_name}" --key "prop_autologin" --value "true" UserPropPut
sudo /usr/local/openvpn_as/scripts/sacli --user "${openvpn_user_name}" GetAutologin | tee "${openvpn_auth_file}"
chmod 0600 "${openvpn_auth_file}"
