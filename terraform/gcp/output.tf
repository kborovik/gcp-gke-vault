output "google_project" {
  description = "GCP project"
  value       = var.project_id
}

output "google_region" {
  description = "GCP region"
  value       = var.region
}

output "dns_zone" {
  description = "Private DNS zone"
  value       = try(google_dns_managed_zone.private.dns_name, null)
}

output "gke_names" {
  description = "GKE cluster names"
  value       = try([google_container_cluster.gke_01[0].name], null)
}

output "vault_dns_records" {
  description = "Vault GKE Internal LoadBalancer DNS records"
  value       = try(local.vault_dns_records, null)
}

output "vault_service_account" {
  description = "Hashicorp Vault Service Account"
  value       = try(google_service_account.vault.email, null)
}

output "vault_gcpckms_seal_key_ring" {
  description = "Google KMS key ring"
  value       = try(google_kms_key_ring.us_central1.name, null)
}

output "vault_gcpckms_seal_crypto_key" {
  description = "Google KMS Vault auto-unseal key"
  value       = try(google_kms_crypto_key.vault_seal_gcp_hsm.name, null)
}

output "internal_ip_gke_proxy" {
  description = "GKE Proxy Internal IP address"
  value       = try(google_compute_address.internal_ip_gke_proxy[0].address, null)
}

output "external_ip_vpn" {
  description = "Bastion external IP address"
  value       = try(google_compute_address.external_ip_vpn[0].address, null)
}

output "ca_pool_name" {
  description = "GCP Private CA pool name"
  value       = try(google_privateca_ca_pool.main[0].name, null)
}

output "root_ca_certificate" {
  description = "Root CA PEM Certificate"
  value       = try(google_privateca_certificate_authority.main[0].pem_ca_certificates[0], null)
}

output "root_ca_certificate_url" {
  description = "Root CA PEM Certificate URL"
  value       = try(google_privateca_certificate_authority.main[0].access_urls[0].ca_certificate_access_url, null)
}
