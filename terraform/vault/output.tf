output "approle" {
  description = "Export configured AppRole to test scripts"
  value = [
    {
      role_name          = "${vault_approle_auth_backend_role.test1.role_name}"
      role_id            = "${vault_approle_auth_backend_role.test1.role_id}"
      google_secret_name = "${data.google_secret_manager_secret.approle_test1.secret_id}"
    },
    {
      role_name          = "${vault_approle_auth_backend_role.test2.role_name}"
      role_id            = "${vault_approle_auth_backend_role.test2.role_id}"
      google_secret_name = "${data.google_secret_manager_secret.approle_test2.secret_id}"
    },
  ]
}
