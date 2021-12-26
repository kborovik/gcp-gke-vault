terraform {
  required_version = "~>1.1"

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "=3.1.1"
    }
    google = {
      source  = "hashicorp/google"
      version = "=4.5.0"
    }
  }

  backend "gcs" {}
}
