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
  bucket = google_storage_bucket.dataproc_01_staging.id
  role   = "roles/storage.admin"
  members = [
    "serviceAccount:${google_service_account.dataproc_01.email}",
  ]
}

resource "google_storage_bucket" "dataproc_01_temp" {
  name                        = "dataproc-01-temp-${var.project_id}"
  location                    = "US-CENTRAL1"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_iam_binding" "dataproc_01_temp" {
  bucket = google_storage_bucket.dataproc_01_temp.id
  role   = "roles/storage.admin"
  members = [
    "serviceAccount:${google_service_account.dataproc_01.email}",
  ]
}

locals {
  dataproc_bucket_count = 3
}

resource "google_storage_bucket" "dataproc_01_data" {
  count                       = local.dataproc_bucket_count
  name                        = "dataproc-01-data${count.index}-${var.project_id}"
  location                    = "US-CENTRAL1"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_iam_binding" "dataproc_01_data" {
  count  = local.dataproc_bucket_count
  bucket = google_storage_bucket.dataproc_01_data[count.index].id
  role   = "roles/storage.admin"
  members = [
    "serviceAccount:${google_service_account.dataproc_01.email}",
  ]
}
