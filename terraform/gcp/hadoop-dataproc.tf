resource "google_dataproc_cluster" "basic_cluster" {
  ggraceful_decommission_timeout = "120s"
  name                           = "basic-cluster"
  region                         = "us-central1"
}
