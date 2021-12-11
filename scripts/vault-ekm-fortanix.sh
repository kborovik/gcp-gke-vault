#!/usr/bin/env bash

# shellcheck disable=SC1091
# shellcheck disable=SC2086

#
# Create Fortanix Cloud EKM key
# https://cloud.google.com/kms/docs/managing-external-keys
#

fortanix_key_name="dev-hwgcp-vault-aes256-01"
fortanix_key_uuid="ae2fce17-c166-40f6-8921-54319dfa4fce"
fortanix_uri="https://sdkms.fortanix.com/v0/gcp/key/${fortanix_key_uuid}"
gcp_keyring="us-west2"
gcp_region="us-west2"

if ! gcloud kms keys describe "${fortanix_key_name}" --keyring="${gcp_keyring}" --location="${gcp_region}"; then

  gcloud kms keys create "${fortanix_key_name}" \
    --keyring="${gcp_keyring}" \
    --location="${gcp_region}" \
    --purpose="encryption" \
    --protection-level="external" \
    --skip-initial-version-creation \
    --default-algorithm="external-symmetric-encryption"

  gcloud kms keys versions create \
    --key="${fortanix_key_name}" \
    --keyring="${gcp_keyring}" \
    --location="${gcp_region}" \
    --external-key-uri="${fortanix_uri}" \
    --primary
fi
