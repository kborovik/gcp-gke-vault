resource "google_privateca_ca_pool" "main" {
  count    = var.enable_ca_tls == true ? 1 : 0
  name     = "ca-pool-01"
  location = var.region
  tier     = "DEVOPS"

  publishing_options {
    publish_ca_cert = true
    publish_crl     = false
  }

  lifecycle {
    prevent_destroy = true
  }
}


resource "google_privateca_certificate_authority" "main" {
  count                    = var.enable_ca_tls == true ? 1 : 0
  pool                     = google_privateca_ca_pool.main[count.index].name
  certificate_authority_id = "root-ca-01"
  location                 = var.region
  lifetime                 = "126144000s"

  config {
    subject_config {
      subject {
        common_name         = "RootCA GCP ${var.project_id}"
        organization        = var.root_ca_tls_subject.organization
        organizational_unit = var.root_ca_tls_subject.organizational_unit
        street_address      = var.root_ca_tls_subject.street_address
        locality            = var.root_ca_tls_subject.locality
        province            = var.root_ca_tls_subject.province
        country_code        = var.root_ca_tls_subject.country_code
        postal_code         = var.root_ca_tls_subject.postal_code
      }
    }

    x509_config {
      ca_options {
        is_ca                  = true
        max_issuer_path_length = 0
      }
      key_usage {
        base_key_usage {
          digital_signature  = true
          content_commitment = true
          key_encipherment   = true
          data_encipherment  = true
          key_agreement      = true
          cert_sign          = true
          crl_sign           = true
          decipher_only      = true
        }
        extended_key_usage {
          server_auth      = true
          client_auth      = true
          email_protection = true
          code_signing     = true
          time_stamping    = true
        }
      }
    }
  }

  key_spec {
    algorithm = "EC_P256_SHA256"
  }

  lifecycle {
    prevent_destroy = true
  }
}
