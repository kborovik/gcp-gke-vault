data "google_project" "main" {
  project_id = var.project_id
}

data "google_compute_zones" "available" {
  project = var.project_id
  region  = var.region
}

data "google_compute_default_service_account" "default" {
  project = var.project_id
}
