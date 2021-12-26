/*

Create data disk for Vault GKE deployment and attach daily snapshot policy

! IMPORTANT The name of google_compute_disk is set to match the name of PersistentVolume in Vault HELM chart

*/
locals {
  zone_count = 3
}

resource "google_compute_disk" "vault_data_0" {
  count = local.zone_count
  name  = "data-${local.vault_dns_records[0].name}-${count.index}"
  type  = "pd-standard"
  zone  = data.google_compute_zones.available.names[count.index % local.zone_count]
  size  = 10

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      snapshot
    ]
  }
}

resource "google_compute_disk_resource_policy_attachment" "vault_data_0" {
  count = local.zone_count
  name  = google_compute_resource_policy.snapshot_daily.name
  disk  = google_compute_disk.vault_data_0[count.index].name
  zone  = data.google_compute_zones.available.names[count.index % local.zone_count]
}
