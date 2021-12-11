/*

AppRole auth backend

*/
resource "vault_auth_backend" "approle" {
  type = "approle"
}

/*

AppRole "test1"

*/
resource "vault_approle_auth_backend_role" "test1" {
  backend        = vault_auth_backend.approle.path
  role_name      = "test1"
  bind_secret_id = true
  token_period   = 86400
  token_num_uses = 0

  token_policies = [
    vault_policy.vault_client.id,
    vault_policy.approle_test1.id,
  ]
}

resource "vault_approle_auth_backend_role_secret_id" "test1" {
  role_name = vault_approle_auth_backend_role.test1.role_name
}

resource "vault_approle_auth_backend_login" "test1" {
  backend   = vault_auth_backend.approle.path
  role_id   = vault_approle_auth_backend_role.test1.role_id
  secret_id = vault_approle_auth_backend_role_secret_id.test1.secret_id
}

resource "google_secret_manager_secret_version" "test1" {
  secret      = data.google_secret_manager_secret.approle_test1.id
  secret_data = vault_approle_auth_backend_login.test1.secret_id
}

/*

AppRole "test2"

*/
resource "vault_approle_auth_backend_role" "test2" {
  backend        = vault_auth_backend.approle.path
  role_name      = "test2"
  bind_secret_id = true
  token_period   = 86400
  token_num_uses = 0

  token_policies = [
    vault_policy.vault_client.id,
    vault_policy.approle_test2.id,
  ]
}

resource "vault_approle_auth_backend_role_secret_id" "test2" {
  role_name = vault_approle_auth_backend_role.test2.role_name
}

resource "vault_approle_auth_backend_login" "test2" {
  backend   = vault_auth_backend.approle.path
  role_id   = vault_approle_auth_backend_role.test2.role_id
  secret_id = vault_approle_auth_backend_role_secret_id.test2.secret_id
}

resource "google_secret_manager_secret_version" "test2" {
  secret      = data.google_secret_manager_secret.approle_test2.id
  secret_data = vault_approle_auth_backend_login.test2.secret_id
}
