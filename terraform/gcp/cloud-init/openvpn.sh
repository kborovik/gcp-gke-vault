#!/usr/bin/env bash
# shellcheck disable=SC2154
# shellcheck disable=SC2086
while [[ "$(pgrep apt-get)" ]]; do
  sleep 5
done
apt-get -y update
apt-get -y upgrade
apt-get -y install vim less bash-completion bind9-dnsutils iputils-ping jq netcat-openbsd nmap
apt-get -y autoremove
wget -o /usr/local/share/ca-certificates/gcp.crt ${root_ca_crt}
update-ca-certificates
timedatectl set-timezone 'America/Toronto'
