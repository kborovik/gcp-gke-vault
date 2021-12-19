<!-- @format -->

## About

Hashicorp Vault Kubernetes deployment based on the official Hashicorp Vault HELM chart. (https://www.vaultproject.io/docs/platform/k8s/helm)

The official Hashicorp HELM chart was re-written to narrow the deployment scope and simplify the HELM chart. The current HELM chart implementation depends on the GCP Terraform code and is not intended to be used as a stand-alone HELM chart.

Changes:

- Kubernetes Services to enable GKE internal load-balancer
- Kubernetes Services publishNotReadyAddresses to enable predictable HA failover
- Kubernetes Secrets to allow TLS certificate automated deployment
- Kubernetes ServiceAccount to allow key-less Auto-Unseal operations
- Kubernetes PersistentVolume to allow consistent attachment Vault data GCP Persistent Disks (GCP Snapshot Policy)
