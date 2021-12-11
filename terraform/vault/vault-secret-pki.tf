resource "vault_mount" "pki" {
  path                      = "pki"
  type                      = "pki"
  description               = "Default PKI Secret"
  default_lease_ttl_seconds = 3600
  max_lease_ttl_seconds     = 86400
  options                   = {}
}
