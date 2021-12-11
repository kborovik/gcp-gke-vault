/*

Hashicorp Vault GKE DNS records

*/
locals {
  vault_dns_records = [
    {
      "name" : "vault1"
      "address" : "10.128.128.3"
    },
  ]
}
