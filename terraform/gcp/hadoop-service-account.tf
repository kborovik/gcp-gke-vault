/*

GCP Dataproc Service Account

*/
resource "google_service_account" "dataproc_01" {
  account_id   = "dataproc-01"
  display_name = "Dataproc (Hadoop) Service Account"
}

/*

Assign Dataproc Worker (roles/dataproc.worker) role to Dataproc Service Account

*/
resource "google_service_account_iam_binding" "dataproc_worker" {
  service_account_id = google_service_account.dataproc_01.name
  role               = "roles/dataproc.worker"

  members = [
    "serviceAccount:${google_service_account.dataproc_01.email}",
  ]
}
