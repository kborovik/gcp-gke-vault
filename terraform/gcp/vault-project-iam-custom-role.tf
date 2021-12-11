/*

Custom IAM Role to allow auto-auth for Hashicorp Vault Server

*/
resource "google_project_iam_custom_role" "vault_server" {
  project     = var.project_id
  role_id     = "custom.vault.vaultServer"
  title       = "Custom Hashicorp Vault Server"
  description = "Custom Hashicorp Vault Server"

  permissions = [
    "compute.instanceGroups.list",
    "compute.instances.get",
    "iam.serviceAccountKeys.get",
    "iam.serviceAccounts.get",
  ]
}
