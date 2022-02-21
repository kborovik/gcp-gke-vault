/*

Project general settings

*/
project_id = "lab5-vault-d1"
region     = "us-central1"

/*

GCE instances

*/
enable_gke_proxy      = true
enable_vpn_host       = true
instance_machine_type = "e2-small"
ssh_keys = [
  {
    user   = "cloudbuild"
    pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHqh8wp++IcsVe15c01zX2yKaT3y381KBlJpWErABRyL"
  },
]

/*

Kubernetes cluster

*/
enable_gke_01    = true
gke_machine_type = "e2-medium"

/*

Dataproc Clusters (Hadoop/Spark)

*/
enable_dataproc_01    = false
dataproc_machine_type = "e2-medium"

/*

GCP Certificate Authority Service (Root CA)

*/
enable_ca_tls = true
root_ca_tls_subject = {
  common_name         = ""
  organization        = "Lab5 DevOps Inc."
  organizational_unit = "Cloud Operations"
  street_address      = ""
  locality            = "Toronto"
  province            = "Ontario"
  country_code        = "CA"
  postal_code         = ""
}

/*

Cloud Build

*/
enable_cloudbuild_pull_request = true
enable_cloudbuild_push         = true
enable_cloudbuild_tag          = false
