/*

KMS Key Rings are location specific. 
We create Key Rings for each GCP Region in use

https://cloud.google.com/kms/docs/managing-external-keys

*/
resource "google_kms_key_ring" "us_central1" {
  name     = "us-central1"
  location = "us-central1"
}
