#!/usr/bin/env bash
# shellcheck disable=SC2154
# shellcheck disable=SC2086
while [[ "$(pgrep apt-get)" ]]; do
  sleep 5
done
curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
curl -fsSL https://baltocdn.com/helm/signing.asc | apt-key add -
echo "deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable.list
apt-get -y update
apt-get -y upgrade
apt-get -y install vim less bash-completion bind9-dnsutils iputils-ping git jq nmap netcat-openbsd tmux terraform vault kubectl helm
apt-get -y autoremove
curl -fsSLo /usr/local/share/ca-certificates/gcp.crt ${root_ca_crt}
update-ca-certificates
timedatectl set-timezone 'America/Toronto'
