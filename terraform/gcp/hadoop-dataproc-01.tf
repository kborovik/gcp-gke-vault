/*

Dataproc (Hadoop) clusters

Dataproc best practices guide:
https://cloud.google.com/blog/topics/developers-practitioners/dataproc-best-practices-guide

*/
resource "google_dataproc_cluster" "dataproc_01" {
  count                         = var.enable_dataproc_01 == true ? 1 : 0
  name                          = "dataproc-01"
  region                        = var.region
  graceful_decommission_timeout = "3600s"

  depends_on = [
    google_project_iam_binding.dataproc_worker
  ]

  cluster_config {

    staging_bucket = google_storage_bucket.dataproc_01_staging.id
    temp_bucket    = google_storage_bucket.dataproc_01_temp.id

    gce_cluster_config {
      service_account = google_service_account.dataproc_01.email
      service_account_scopes = [
        "https://www.googleapis.com/auth/cloud-platform",
        "https://www.googleapis.com/auth/cloud.useraccounts.readonly",
        "https://www.googleapis.com/auth/devstorage.read_write",
        "https://www.googleapis.com/auth/logging.write",

      ]
      subnetwork       = google_compute_subnetwork.dataproc.id
      internal_ip_only = true
      tags             = ["dataproc-01"]
      metadata         = {}
      zone             = "${var.region}-c"
    }

    master_config {
      num_instances = 1
      machine_type  = var.dataproc_machine_type
      disk_config {
        boot_disk_type    = "pd-standard"
        boot_disk_size_gb = 30
      }
    }

    software_config {
      image_version       = "2.0.31-debian10"
      optional_components = []
      override_properties = {}
    }

    worker_config {
      num_instances = 3
      machine_type  = var.dataproc_machine_type
      disk_config {
        boot_disk_type    = "pd-standard"
        boot_disk_size_gb = 30
      }
    }
  }
}
