/*

Google Kubernetes cluster (GKE)

*/
resource "google_container_cluster" "gke_01" {
  count                    = var.enable_gke_01 == true ? 1 : 0
  provider                 = google-beta
  name                     = "${var.project_id}-01"
  description              = "GKE-01"
  project                  = var.project_id
  location                 = var.region
  network                  = google_compute_network.main.self_link
  subnetwork               = google_compute_subnetwork.gke_nodes.self_link
  remove_default_node_pool = true
  initial_node_count       = 1
  min_master_version       = "1.21"
  enable_shielded_nodes    = true
  datapath_provider        = "ADVANCED_DATAPATH"

  node_locations = [
    "${var.region}-a",
    "${var.region}-b",
    "${var.region}-c",
  ]

  release_channel {
    channel = "REGULAR"
  }

  addons_config {
    dns_cache_config {
      enabled = true
    }
  }

  ip_allocation_policy {
    services_secondary_range_name = "services-gke-01"
    cluster_secondary_range_name  = "pods-gke-01"
  }

  database_encryption {
    state    = "ENCRYPTED"
    key_name = google_kms_crypto_key.gke_app_encryption.id
  }

  timeouts {
    create = "30m"
    update = "60m"
    delete = "30m"
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = true
    master_ipv4_cidr_block  = local.gke_master_cidr

    master_global_access_config {
      enabled = true
    }
  }

  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = local.authorized_networks
      content {
        cidr_block   = lookup(cidr_blocks.value, "cidr_block", "")
        display_name = lookup(cidr_blocks.value, "display_name", "")
      }
    }
  }

  maintenance_policy {
    daily_maintenance_window {
      start_time = "08:00"
    }
  }

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }
}

resource "google_container_node_pool" "gke_01_pool1" {
  count              = var.enable_gke_01 == true ? 1 : 0
  name               = "pool1-${count.index + 1}"
  cluster            = google_container_cluster.gke_01[count.index].name
  location           = var.region
  initial_node_count = 1
  max_pods_per_node  = 110

  autoscaling {
    max_node_count = 5
    min_node_count = 1
  }

  node_config {
    machine_type = var.gke_machine_type

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    tags = [
      var.project_id,
    ]

    shielded_instance_config {
      enable_integrity_monitoring = true
      enable_secure_boot          = true
    }
  }
}
