path "sys/auth/*" {
  capabilities = ["create", "delete", "sudo", "update"]
}
path "sys/auth" {
  capabilities = ["read"]
}
path "sys/policies/acl/*" {
  capabilities = ["create", "delete", "list", "read", "sudo", "update"]
}
path "sys/policies/acl" {
  capabilities = ["list"]
}
path "sys/mounts/*" {
  capabilities = ["create", "delete", "list", "read", "sudo", "update"]
}
path "sys/health" {
  capabilities = ["read", "sudo"]
}
path "sys/mounts" {
  capabilities = ["list", "read"]
}
path "auth/*" {
  capabilities = ["create", "delete", "list", "read", "sudo", "update"]
}
