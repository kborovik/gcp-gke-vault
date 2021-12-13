/*

Show Service Account project roles:

  gcloud projects get-iam-policy  --flatten='bindings[].members' --format='table(bindings.role)' --filter='bindings.members=serviceAccount:<service_account>' <project_id>

*/

/*

Custom Role Instance Schedule

*/
resource "google_project_iam_binding" "instance_schedule" {
  project = var.project_id
  role    = google_project_iam_custom_role.instance_schedule.name

  members = [
    "serviceAccount:service-${local.project_number}@compute-system.iam.gserviceaccount.com",
  ]
}

/*

Metric Writer

*/
resource "google_project_iam_binding" "metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"

  members = [
    "serviceAccount:${local.project_number}-compute@developer.gserviceaccount.com",
    "serviceAccount:${google_service_account.vault_client.email}",
  ]
}

/*

Log Writer 

*/
resource "google_project_iam_binding" "log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"

  members = [
    "serviceAccount:${local.project_number}-compute@developer.gserviceaccount.com",
    "serviceAccount:${google_service_account.vault_client.email}",
  ]
}

/*

Project Editor

*/
resource "google_project_iam_binding" "editor" {
  project = var.project_id
  role    = "roles/editor"

  members = [
    "serviceAccount:${local.project_number}@cloudbuild.gserviceaccount.com",
    "serviceAccount:${local.project_number}@cloudservices.gserviceaccount.com",
  ]
}

/*

Project SecretManager Accessor

*/
resource "google_project_iam_binding" "secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"

  members = [
    "serviceAccount:${local.project_number}@cloudbuild.gserviceaccount.com",
  ]
}

/*

Project IAM Admin

*/
resource "google_project_iam_binding" "project_iam_admin" {
  project = var.project_id
  role    = "roles/resourcemanager.projectIamAdmin"

  members = [
    "serviceAccount:${local.project_number}@cloudbuild.gserviceaccount.com",
  ]
}

/*

Project GKE ServiceAgent

*/
resource "google_project_iam_binding" "container_service_agent" {
  project = var.project_id
  role    = "roles/container.serviceAgent"

  members = [
    "serviceAccount:${local.project_number}@cloudbuild.gserviceaccount.com",
    "serviceAccount:service-${local.project_number}@container-engine-robot.iam.gserviceaccount.com",
  ]
}

/*

Service Account Admin

*/
resource "google_project_iam_binding" "service_account_admin" {
  project = var.project_id
  role    = "roles/iam.serviceAccountAdmin"

  members = [
    "serviceAccount:${local.project_number}@cloudbuild.gserviceaccount.com",
  ]
}
