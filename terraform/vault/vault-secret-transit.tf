/*

Transit Secret Storage

*/
resource "vault_mount" "transit" {
  path        = "transit"
  type        = "transit"
  description = "Production Transit Secret"
  options     = {}
}

/*

Transit Keys

*/
resource "vault_transit_secret_backend_key" "test1" {
  name             = "test1"
  backend          = vault_mount.transit.id
  deletion_allowed = true

  depends_on = [
    vault_mount.transit
  ]
}

resource "vault_transit_secret_backend_key" "test2" {
  name             = "test2"
  backend          = vault_mount.transit.id
  deletion_allowed = true

  depends_on = [
    vault_mount.transit
  ]
}
