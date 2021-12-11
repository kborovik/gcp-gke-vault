/*

DNS record and GCP secrets for Hashicorp Vault

IP address reservation for GKE internal LoadBalancer:
We cannot use IP address reservations for GKE Internal LB.
Instead we create DNS records with Terraform and assign IP address in the HELM chart.

*/
resource "google_dns_record_set" "vault_dns_record" {
  count        = length(local.vault_dns_records)
  project      = var.project_id
  managed_zone = google_dns_managed_zone.private.name
  name         = "${local.vault_dns_records[count.index].name}.${google_dns_managed_zone.private.dns_name}"
  rrdatas = [
    local.vault_dns_records[count.index].address,
  ]
  type = "A"
  ttl  = 300
}
