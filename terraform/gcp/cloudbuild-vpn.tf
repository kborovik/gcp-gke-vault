/*

Bastion host

*/
resource "google_compute_address" "internal_ip_vpn" {
  count        = var.enable_vpn_host == true ? 1 : 0
  name         = local.vpn_dns_record[0].name
  region       = var.region
  address_type = "INTERNAL"
  subnetwork   = google_compute_subnetwork.instances.self_link
  address      = local.vpn_dns_record[0].address
}

resource "google_compute_address" "external_ip_vpn" {
  count        = var.enable_vpn_host == true ? 1 : 0
  name         = "${local.vpn_dns_record[0].name}-external-ip"
  region       = var.region
  address_type = "EXTERNAL"
}

resource "google_dns_record_set" "dns_a_record_bastion" {
  count        = var.enable_vpn_host == true ? 1 : 0
  project      = var.project_id
  managed_zone = google_dns_managed_zone.private.name
  name         = "${local.vpn_dns_record[0].name}.${google_dns_managed_zone.private.dns_name}"
  rrdatas = [
    local.vpn_dns_record[0].address,
  ]
  type = "A"
  ttl  = 300
}

resource "google_compute_instance" "openvpn" {
  count                     = var.enable_vpn_host == true ? 1 : 0
  name                      = local.vpn_dns_record[0].name
  machine_type              = var.instance_machine_type
  desired_status            = "RUNNING"
  deletion_protection       = false
  can_ip_forward            = false
  allow_stopping_for_update = true
  zone                      = "${var.region}-a"

  tags = [
    var.project_id,
    "openvpn",
  ]

  labels = {
    "os_patch"       = "yes"
    "daily_shutdown" = "yes"
  }

  metadata = {
    "ssh-keys" = join("\n", [for key in var.ssh_keys : "${key.user}:${key.pubkey}"])
    "user-data" = templatefile("cloud-init/openvpn.sh",
      {
        root_ca_crt = google_privateca_certificate_authority.main[0].access_urls[0].ca_certificate_access_url
      }
    )
  }

  boot_disk {
    initialize_params {
      image = "ubuntu-minimal-2004-lts"
      size  = 10
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.instances.self_link
    network_ip = google_compute_address.internal_ip_vpn[count.index].address
    access_config {
      nat_ip = google_compute_address.external_ip_vpn[count.index].address
    }
  }

  service_account {
    scopes = ["cloud-platform"]
  }

  shielded_instance_config {
    enable_secure_boot = true
  }

  resource_policies = [
    google_compute_resource_policy.instance_start_stop.self_link
  ]

  depends_on = [
    google_project_iam_binding.instance_schedule,
    google_compute_address.internal_ip_vpn,
    google_compute_address.external_ip_vpn,
  ]
}
