/*

Enable GCP authentication backend

*/
resource "vault_gcp_auth_backend" "gcp" {
  description = "Google (GCP) Auth backend"
}

/*

Google GCP backend role bound to GCP Service Account

*/
resource "vault_gcp_auth_backend_role" "gce_test_sa" {
  role           = "gce-test-sa"
  type           = "gce"
  token_period   = 86400
  token_num_uses = 0

  backend = vault_gcp_auth_backend.gcp.id

  token_policies = [
    vault_policy.vault_client.id,
    vault_policy.gce_test_sa.id,
  ]

  bound_service_accounts = [
    data.google_service_account.vault_client.email,
  ]
}

/*

Google GCP backend role bound to GCE labels

*/
resource "vault_gcp_auth_backend_role" "gce_test_label" {
  role           = "gce-test-label"
  type           = "gce"
  token_period   = 86400
  token_num_uses = 0

  backend = vault_gcp_auth_backend.gcp.id

  token_policies = [
    vault_policy.vault_client.id,
    vault_policy.gce_test_label.id,
  ]

  bound_labels = [
    "vault_gce_role:gce-test-label"
  ]
}
