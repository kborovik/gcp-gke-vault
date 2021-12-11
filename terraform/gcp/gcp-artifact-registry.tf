/*

Create GCP Artifact Registry for Docker containers

*/
resource "google_artifact_registry_repository" "containers" {
  provider      = google-beta
  repository_id = "containers"
  format        = "DOCKER"
  location      = var.region
}

/*

Assign Artifact Registry AIM roles

*/
resource "google_artifact_registry_repository_iam_binding" "containers_reader" {
  provider   = google-beta
  location   = google_artifact_registry_repository.containers.location
  repository = google_artifact_registry_repository.containers.name
  role       = "roles/artifactregistry.reader"
  members = [
    "serviceAccount:${local.project_number}-compute@developer.gserviceaccount.com",
  ]
}
