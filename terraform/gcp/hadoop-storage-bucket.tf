/*

Dataproc GCP Storage buckets

*/
resource "google_storage_bucket" "dataproc_01_staging" {
  name                        = "dataproc-01-staging-${var.project_id}"
  location                    = "US-CENTRAL1"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_iam_binding" "dataproc_01_staging" {
  bucket = google_storage_bucket.dataproc_01_staging.name
  role   = "roles/storage.admin"
  members = [
    google_service_account.dataproc_01.email
  ]
}

resource "google_storage_bucket" "dataproc_01_temp" {
  name                        = "dataproc-01-temp-${var.project_id}"
  location                    = "US-CENTRAL1"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_iam_binding" "dataproc_01_temp" {
  bucket = google_storage_bucket.dataproc_01_temp.name
  role   = "roles/storage.admin"
  members = [
    google_service_account.dataproc_01.email
  ]
}
