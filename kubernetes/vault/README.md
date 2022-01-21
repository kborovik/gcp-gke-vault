<!-- @format -->

## About

Hashicorp Vault Kubernetes deployment based on the official Hashicorp Vault HELM chart. (https://www.vaultproject.io/docs/platform/k8s/helm)

I re-wrote the official Hashicorp HELM chart to narrow the deployment scope and simplify the HELM code. The current HELM chart implementation depends on the GCP Terraform code and is not designed as a stand-alone unit.

Changes:

- Kubernetes Services to enable GKE internal load-balancer
- Kubernetes Services publishNotReadyAddresses to enable predictable failover
- Kubernetes Secrets to allow TLS certificate automated deployment
- Kubernetes Workload Identity to allow key-less Auto-Unseal operations
- Kubernetes PersistentVolume to allow consistent attachment Vault data GCP Persistent Disks (GCP Snapshot Policy)

HashiCorp Vault detailed documentation: [HashiCorp Vault Readme](docs/hashicorp-vault.md)
