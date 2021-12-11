/*

Google Secret Manager

*/
data "google_secret_manager_secret" "approle_test1" {
  secret_id = "${var.vault_dns_name}-approle-test1"
}

data "google_secret_manager_secret" "approle_test2" {
  secret_id = "${var.vault_dns_name}-approle-test2"
}

/*

Google Service Accounts

*/
data "google_service_account" "vault_client" {
  account_id = "hashicorp-vault-client"
}
