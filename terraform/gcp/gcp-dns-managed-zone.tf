/*

Private DNS zone

*/
resource "google_dns_managed_zone" "private" {
  name       = "lab5-gcp"
  dns_name   = "lab5.gcp."
  visibility = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.main.id
    }
  }
}

resource "google_project_iam_custom_role" "dns_editor" {
  project     = var.project_id
  role_id     = "lab5.dns.editor"
  title       = "Lab5 DNS Editor"
  description = "Lab5 DNS Editor"

  permissions = [
    "dns.changes.create",
    "dns.changes.get",
    "dns.changes.list",
    "dns.managedZones.get",
    "dns.managedZones.list",
    "dns.resourceRecordSets.create",
    "dns.resourceRecordSets.delete",
    "dns.resourceRecordSets.get",
    "dns.resourceRecordSets.list",
    "dns.resourceRecordSets.update",
  ]
}

resource "google_project_iam_binding" "dns_editor" {
  project = var.project_id
  role    = google_project_iam_custom_role.dns_editor.name

  members = [
    "serviceAccount:${local.project_number}@cloudbuild.gserviceaccount.com",
  ]
}
