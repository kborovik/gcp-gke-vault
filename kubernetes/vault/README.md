<!-- @format -->

## Hashicorp Vault

Hashicorp Vault Kubernetes deployment based on the official Vault HELM chart (https://www.vaultproject.io/docs/platform/k8s/helm)

The official Hashicorp HELM chart was modified to narrow deployment scope:

- RAFT as Vault storage backend (HA)
- Google Cloud (GKE) as deployment target

Changes:

- Kubernetes Services to enable GKE internal load-balancer
- Kubernetes Secrets to allow TLS certificate automated deployment
- Kubernetes ServiceAccount to allow key-less Auto-Unseal operations
- Kubernetes PersistentVolume to allow consistent attachment Vault data GCP Persistent Disks (GCP Snapshot Policy)

# How to Deploy

Login with Application Default Credentials (ADC) to run deployment scripts from local workstation.

https://cloud.google.com/sdk/gcloud/reference/auth/application-default

```bash
> gcloud auth application-default login
```

**Test Vault HELM chart**

```bash
> cd <git_repository_root>
> ./scripts/vault-deploy.sh -p <google_project> -d <vault_dns_name> -t
```

**Deploy Vault HELM chart**

```bash
> cd <git_repository_root>
> ./scripts/vault-deploy.sh -p <google_project> -d <vault_dns_name>
```
