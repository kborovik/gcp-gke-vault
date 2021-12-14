/*

KMS Key Rings are location specific. 
We create Key Rings for each GCP Region in use

https://cloud.google.com/kms/docs/managing-external-keys

*/
resource "google_kms_key_ring" "us_central1" {
  name     = "us-central1"
  location = "us-central1"
}

/*

KMS Key to encrypt GKE database

*/
resource "google_kms_crypto_key" "gke_app_encryption" {
  name     = "gke-app-encryption"
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

Grant cryptoOperator role to GKE default SA

*/
resource "google_kms_crypto_key_iam_binding" "gke_app_encryption" {
  crypto_key_id = google_kms_crypto_key.gke_app_encryption.id
  role          = "roles/cloudkms.cryptoOperator"
  members = [
    "serviceAccount:service-${local.project_number}@container-engine-robot.iam.gserviceaccount.com"
  ]
}

