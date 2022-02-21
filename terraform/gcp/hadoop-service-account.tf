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
resource "google_project_iam_binding" "dataproc_worker" {
  project = var.project_id
  role    = "roles/dataproc.worker"
  members = [
    "serviceAccount:${google_service_account.dataproc_01.email}",
  ]
}
