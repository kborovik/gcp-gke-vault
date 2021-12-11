/*

CloudBuild private worker pool

gcloud builds worker-pools create  main \
  --peered-network "projects/lab5-vault-d1/global/networks/main" \
  --region us-central1 \
  --project lab5-vault-d1

Useful functions:

gcp-show-cloudbuild-us_central1() {
  local build_id
  gcloud builds list --region=us-central1 --limit=3
  build_id=$(gcloud builds list --region=us-central1 --limit=1 --format="value(id)")
  gcloud builds log --region=us-central1 --stream ${build_id}
}

gcp-show-cloudbuild-global() {
  local build_id
  gcloud builds list --limit=3
  build_id=$(gcloud builds list --limit=1 --format="value(id)")
  gcloud builds log --stream ${build_id}
}

*/

resource "google_cloudbuild_worker_pool" "us_central1_main" {
  name     = "us-central1-main"
  location = var.region

  worker_config {
    disk_size_gb   = 100
    machine_type   = "e2-medium"
    no_external_ip = false
  }

  network_config {
    peered_network = google_compute_network.main.id
  }

  depends_on = [
    google_service_networking_connection.main
  ]
}
