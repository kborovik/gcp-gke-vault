/*

Dataproc (Hadoop) clusters

Dataproc best practices guide:
https://cloud.google.com/blog/topics/developers-practitioners/dataproc-best-practices-guide

*/
resource "google_dataproc_cluster" "dataproc_01" {
  count                         = var.enable_dataproc_01 == true ? 1 : 0
  name                          = "${var.project_id}-01"
  region                        = var.region
  graceful_decommission_timeout = "3600s"

  cluster_config {

    staging_bucket = google_storage_bucket.dataproc_01_staging.id
    temp_bucket    = google_storage_bucket.dataproc_01_temp.id

    gce_cluster_config {
      service_account        = google_service_account.dataproc_01.email
      service_account_scopes = ["cloud-platform"]
      subnetwork             = google_compute_subnetwork.dataproc.id
      internal_ip_only       = true
      tags                   = ["dataproc-01"]
      metadata               = {}
    }

    master_config {
      num_instances = 1
      machine_type  = var.dataproc_machine_type
    }

    # preemptible_worker_config {
    # }

    # software_config {
    # }

    # worker_config {
    # }
  }
}
