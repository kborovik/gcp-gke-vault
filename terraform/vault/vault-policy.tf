/*

Production policies

*/

resource "vault_policy" "vault_admin" {
  name   = "vault-admin"
  policy = file("policies/vault-admin.hcl")
}

resource "vault_policy" "vault_client" {
  name   = "vault-client"
  policy = file("policies/vault-client.hcl")
}

/*

Test policies

*/
resource "vault_policy" "gce_test_sa" {
  name   = "gce-test-sa"
  policy = file("policies/gce-test-sa.hcl")
}

resource "vault_policy" "gce_test_label" {
  name   = "gce-test-label"
  policy = file("policies/gce-test-label.hcl")
}

resource "vault_policy" "approle_test1" {
  name   = "approle-test1"
  policy = file("policies/approle-test1.hcl")
}

resource "vault_policy" "approle_test2" {
  name   = "approle-test2"
  policy = file("policies/approle-test2.hcl")
}
