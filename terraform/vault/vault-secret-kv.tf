/*

Default KV-V2 backend secret

*/
resource "vault_mount" "kv" {
  path        = "kv"
  type        = "kv-v2"
  description = "Default KV-2 Secret"
  options     = {}
}

/*

Test secret

*/
resource "vault_generic_secret" "test1" {
  path         = "${vault_mount.kv.path}/test1"
  disable_read = true

  data_json = <<EOT
{
  "uuid": "set-by-terraform",
  "date": "set-by-terraform"
}
EOT
}

resource "vault_generic_secret" "test2" {
  path         = "${vault_mount.kv.path}/test2"
  disable_read = true

  data_json = <<EOT
{
  "uuid": "set-by-terraform",
  "date": "set-by-terraform"
}
EOT
}

resource "vault_generic_secret" "gce_test_sa" {
  path         = "${vault_mount.kv.path}/gce-test-sa"
  disable_read = true

  data_json = <<EOT
{
  "uuid": "set-by-terraform",
  "date": "set-by-terraform"
}
EOT
}

resource "vault_generic_secret" "gce_test_label" {
  path         = "${vault_mount.kv.path}/gce-test-label"
  disable_read = true

  data_json = <<EOT
{
  "uuid": "set-by-terraform",
  "date": "set-by-terraform"
}
EOT
}
