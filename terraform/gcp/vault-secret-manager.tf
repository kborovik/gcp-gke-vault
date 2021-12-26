/*

Secret Manager records for Vault Secrets

*/
resource "google_secret_manager_secret" "vault_tls_key" {
  count     = length(local.vault_dns_records)
  secret_id = "${local.vault_dns_records[count.index].name}-tls-key"

  replication {
    automatic = true
  }

  lifecycle {
    prevent_destroy = true
  }

}

resource "google_secret_manager_secret" "vault_tls_crt" {
  count     = length(local.vault_dns_records)
  secret_id = "${local.vault_dns_records[count.index].name}-tls-crt"

  replication {
    automatic = true
  }

  lifecycle {
    prevent_destroy = true
  }

}

resource "google_secret_manager_secret" "vault_key" {
  count     = length(local.vault_dns_records)
  secret_id = "${local.vault_dns_records[count.index].name}-vault-key"

  replication {
    automatic = true
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_secret_manager_secret" "vault_terraform_state_key" {
  count     = length(local.vault_dns_records)
  secret_id = "${local.vault_dns_records[count.index].name}-terraform-state-key"

  replication {
    automatic = true
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_secret_manager_secret" "vault_license_key" {
  count     = length(local.vault_dns_records)
  secret_id = "${local.vault_dns_records[count.index].name}-license-key"

  replication {
    automatic = true
  }

  lifecycle {
    prevent_destroy = true
  }
}

/*

Test resources

*/
resource "google_secret_manager_secret" "approle_test1" {
  count     = length(local.vault_dns_records)
  secret_id = "${local.vault_dns_records[count.index].name}-approle-test1"

  replication {
    automatic = true
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_secret_manager_secret" "approle_test2" {
  count     = length(local.vault_dns_records)
  secret_id = "${local.vault_dns_records[count.index].name}-approle-test2"

  replication {
    automatic = true
  }

  lifecycle {
    prevent_destroy = true
  }
}
