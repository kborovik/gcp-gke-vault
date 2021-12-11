/*

GCP Vault Service Account (GSA) for KMS Auto-Unseal
AKA: Vault Server

*/
resource "google_service_account" "vault" {
  account_id   = "hashicorp-vault"
  display_name = "Hashicorp Vault Service Account"
}

/*

Assign workloadIdentityUser role to Kubernetes Vault Service Account (KSA)

TODO: code a loop for workload_identity_user members to avoid manual serviceAccount addition

*/
resource "google_service_account_iam_binding" "workload_identity_user" {
  count              = var.enable_gke_01 == true ? 1 : 0
  service_account_id = google_service_account.vault.name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "serviceAccount:${var.project_id}.svc.id.goog[${local.vault_dns_records[0].name}/${local.vault_dns_records[0].name}]",
  ]

  depends_on = [
    google_container_cluster.gke_01[0]
  ]
}

/*

Vault Client GCP Service Account

*/
resource "google_service_account" "vault_client" {
  account_id   = "hashicorp-vault-client"
  display_name = "Hashicorp Vault Client Service Account"
}

/*

Assign serviceAccountTokenCreator role to Vault Client Service Account

*/
resource "google_service_account_iam_binding" "service_account_token_creator" {
  service_account_id = google_service_account.vault_client.name
  role               = "roles/iam.serviceAccountTokenCreator"

  members = [
    "serviceAccount:${google_service_account.vault_client.email}",
  ]
}
