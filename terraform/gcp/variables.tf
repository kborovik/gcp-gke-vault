/*

General project settings

*/
variable "project_id" {
  description = "GCP Project Id"
  type        = string
  default     = null
}

variable "region" {
  description = "Default GCP region"
  type        = string
  default     = "us-central1"
}

/*

Virtual Machines

*/
variable "ssh_keys" {
  description = "list of public ssh keys that have access to the VM"
  type = list(object({
    user   = string
    pubkey = string
  }))
  default = [
    {
      user   = null
      pubkey = null
    }
  ]
}

variable "enable_gke_proxy" {
  description = "GCP Proxy hosts build switch"
  type        = bool
  default     = false
}

variable "enable_vpn_host" {
  description = "VPN hosts build switch"
  type        = bool
  default     = false
}

variable "instance_machine_type" {
  description = "GCP Proxy host machine type"
  type        = string
  default     = "e2-small"
}

/*

Kubernetes (GKE)

*/
variable "enable_gke_01" {
  description = "Build flag for Kubernetes cluster"
  type        = bool
  default     = false
}

variable "gke_machine_type" {
  description = "Machine type for GKE servers"
  type        = string
  default     = "e2-medium"
}

/*

Dataproc Clusters (Hadoop/Spark)

*/
variable "enable_dataproc_01" {
  description = "Build flag for Dataproc cluster"
  type        = bool
  default     = false
}

variable "dataproc_machine_type" {
  description = "Machine type for Dataproc servers"
  type        = string
  default     = "e2-medium"
}

/*

GCP Certificate Authority Services (Root CA)

*/
variable "enable_ca_tls" {
  description = "Build flag for Certificate Authority (Root CA)"
  type        = bool
  default     = false
}

variable "root_ca_tls_subject" {
  description = "The `subject` block for the root CA certificate."
  type = object({
    common_name         = string,
    organization        = string,
    organizational_unit = string,
    street_address      = string,
    locality            = string,
    province            = string,
    country_code        = string,
    postal_code         = string,
  })

  default = {
    common_name         = "Root CA gcp_project_id"
    organization        = "Example Inc."
    organizational_unit = "Department of Certificate Authority"
    street_address      = "Example Street"
    locality            = "Toronto"
    province            = "Ontario"
    country_code        = "CA"
    postal_code         = "A1A A1A"
  }
}

/*

GCP Cloud Build

*/
variable "enable_cloudbuild_pull_request" {
  description = "Build flag for Cloud Build Trigger"
  type        = bool
  default     = false
}

variable "enable_cloudbuild_push" {
  description = "Build flag for Cloud Build Trigger"
  type        = bool
  default     = false
}

variable "enable_cloudbuild_tag" {
  description = "Build flag for Cloud Build Trigger"
  type        = bool
  default     = false
}
