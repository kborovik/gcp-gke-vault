/*

General Terraform local variables

*/
locals {
  project_number = data.google_project.main.number
}

/*

Network Settings

*/
locals {
  instances_cidr  = "10.128.0.0/18"
  dataproc_cidr   = "10.128.64.0/18"
  gke_nodes_cidr  = "10.128.128.0/18"
  gke_master_cidr = "10.128.255.240/28"
}

/*

GKE local settings

*/
locals {
  authorized_networks = [
    {
      cidr_block   = "10.128.0.0/16"
      display_name = "GCP networks"
    },
  ]
}

/*

Enable GCP Project Services

*/
locals {
  project_services = [
    "appengine.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudasset.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudkms.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "cloudscheduler.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "containeranalysis.googleapis.com",
    "dataproc.googleapis.com",
    "dns.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "networkservices.googleapis.com",
    "privateca.googleapis.com",
    "secretmanager.googleapis.com",
    "servicemanagement.googleapis.com",
    "servicenetworking.googleapis.com",
  ]
}
