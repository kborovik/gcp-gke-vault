/*
Service Networking Connection for CloudSQL instances
https://cloud.google.com/vpc/docs/configure-private-services-access

Allocating an IP address range

gcloud compute addresses create google-managed-services-main \
    --global \
    --network="main" \
    --purpose=VPC_PEERING \
    --prefix-length=16 \
    --addresses="10.126.0.0" \
    --project=lab5-shared-dev

Changing the private service access IP address range:

gcloud services vpc-peerings update \
  --network="main" \
  --ranges="google-managed-services-main" \
  --service=servicenetworking.googleapis.com \
  --project=lab5-shared-dev \
  --force

*/

resource "google_compute_global_address" "google_managed_services" {
  project       = var.project_id
  name          = "google-managed-services"
  purpose       = "VPC_PEERING"
  address       = "10.254.0.0"
  prefix_length = 16
  ip_version    = "IPV4"
  address_type  = "INTERNAL"
  network       = google_compute_network.main.self_link
}


resource "google_service_networking_connection" "main" {
  network                 = google_compute_network.main.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.google_managed_services.name]
}
