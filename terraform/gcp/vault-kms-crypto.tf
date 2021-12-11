/*

Vault auto-unseal key

*/
resource "google_kms_crypto_key" "vault_seal_gcp_hsm" {
  name     = "vault-seal-gcp-hsm"
  purpose  = "ENCRYPT_DECRYPT"
  key_ring = google_kms_key_ring.us_central1.id

  version_template {
    algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
    protection_level = "HSM"
  }

  lifecycle {
    prevent_destroy = true
  }
}

/*

Grant cryptoOperator role to Vault SA

*/
resource "google_kms_crypto_key_iam_binding" "vault_seal_gcp_hsm" {
  crypto_key_id = google_kms_crypto_key.vault_seal_gcp_hsm.id
  role          = "roles/cloudkms.cryptoOperator"
  members = [
    "serviceAccount:${google_service_account.vault.email}"
  ]
}
