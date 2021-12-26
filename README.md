<!-- @format -->

# About

The project implements Continuous Delivery (CD) of Hashicorp Vault into a private GCP Kubernetes cluster (GKE).

GCP Cloud Build pipeline steps:

- Build GCP infrastructure with Terraform code (VPC, GKE, Vault storage, etc.)
- Deploy HashiCorp Vault with HELM chart
- Configure HashiCorp Vault with Terraform code (auth, policies, mounts, etc.)
- Test HashiCorp Vault GKE failover and RAFT replication
- Test HashiCorp Vault configuration (app_roles, transit, etc.)

## Implemented GCP Services

- GCP Kubernetes Engine (GKE) with Shared VPC
- GCP Certificate Authority (Root CA)
- GCP Cloud Key Management (KMS)
- GCP Cloud Build (CI/CD)
- GCP Cloud DNS
- GCP IAM Custom roles
- GCE OS Patch Policies (automatic weekly OS patching)

## Hashicorp Vault

Hashicorp Vault Kubernetes deployment based on the official Hashicorp Vault HELM chart. (https://www.vaultproject.io/docs/platform/k8s/helm)

The official Hashicorp HELM chart was re-written to narrow the deployment scope and simplify the HELM chart. The current HELM chart implementation depends on the GCP Terraform code and is not intended to be used as a stand-alone HELM chart.

Changes:

- Kubernetes Services to enable GKE internal load-balancer
- Kubernetes Services publishNotReadyAddresses to enable predictable HA failover
- Kubernetes Secrets to allow TLS certificate automated deployment
- Kubernetes ServiceAccount to allow key-less Auto-Unseal operations
- Kubernetes PersistentVolume to allow consistent attachment Vault data GCP Persistent Disks (GCP Snapshot Policy)

## Deployment Environments

The repository structure assumes the deployment target is a single GCP project. All deployment environments (GCP Projects) build from the same commit.

Example of deployment environments map:

| GCP Project ID  | Region      | Purpose            | VPC IP Space  | Availability |
| --------------- | ----------- | ------------------ | ------------- | ------------ |
| gcp-project-dev | us-central1 | Development (DEV)  | 10.128.0.0/16 | 00.0%        |
| gcp-project-stg | us-central1 | Staging (STG)      | 10.128.0.0/16 | 70.0%        |
| gcp-project-uat | us-central1 | Acceptance (UAT)   | 10.128.0.0/16 | 80.0%        |
| gcp-project-lod | us-central1 | Load Testing (LOD) | 10.128.0.0/16 | 90.0%        |
| gcp-project-prd | us-central1 | Production (PRD)   | 10.128.0.0/16 | 99.9%        |

Note: All GCP projects use the same IP schema

# How to Deploy

All deployment scripts are located in the `scripts/` folder.

Login with Application Default Credentials (ADC) to run deployment scripts from local workstation.

https://cloud.google.com/sdk/gcloud/reference/auth/application-default

```bash
> gcloud auth application-default login
```

The deployment scripts are split into **deployment layers**. Each deployment layer can be executed entirely independently from the other. The CI/CD pipeline runs each deployment script in a defined order. `cloudbuild/cloudbuild.yaml`

Deployment Layers:

- Terraform code (all GCP resources)
- HELM charts (all Kubernetes applications)
- Deployment test scripts (Vault policies)

## GCP Resources Deployment

All deployment scripts perform a narrow function. The CI/CD pipeline aggregates the deployments scripts into a single flow.

**Test Terraform scripts**

```bash
> cd <git_repository_root>
> ./scripts/gcp-deploy.sh -p <google_project>
```

**Deploy Terraform scripts**

```bash
> cd <git_repository_root>
> ./scripts/gcp-deploy.sh -p <google_project> -a
```

## Vault Deployment

**(One-time) Generate Vault TLS certificates**

```bash
> cd <git_repository_root>
> ./scripts/vault-generate-tls-cert.sh -p <google_project> -n <vault_dns_name>
```

**Test Vault HELM chart**

```bash
> cd <git_repository_root>
> ./scripts/vault-deploy.sh -p <google_project> -n <vault_dns_name> -t
```

**Deploy Vault HELM chart**

```bash
> cd <git_repository_root>
> ./scripts/vault-deploy.sh -p <google_project> -n <vault_dns_name>
```

**(One-time) Initialize Vault**

```bash
> cd <git_repository_root>
> ./scripts/vault-init.sh -p <google_project> -n <vault_dns_name>
```

## Vault Configuration

**Test Vault configuration**

```bash
> cd <git_repository_root>
> ./scripts/vault-config.sh -p <google_project> -n <vault_dns_name>
```

**Apply Vault configuration**

```bash
> cd <git_repository_root>
> ./scripts/vault-config.sh -p <google_project> -n <vault_dns_name> -a
```

## Vault Deployment Tests

**Test Vault GKE High Availability (HA)**

```bash
> cd <git_repository_root>
> ./scripts/vault-test-gke.sh -p <google_project> -n <vault_dns_name>
```

**Test Vault AppRoles**

```bash
> cd <git_repository_root>
> ./scripts/vault-test-approle.sh -p <google_project> -n <vault_dns_name> -r <approle>
```

**Test Vault Google Cloud Auth Method**

```bash
> cd <git_repository_root>
> scp ./scripts/vault-test-gcp.sh gcp-instance:~
> ssh gcp-instance
> ./vault-test-gcp.sh <vault_ip_address>
```

## Cloud Build Deployment (CI/CD)

### Cloud Build Deployment from GitHub

Cloud Build configuration files are located in `cloudbuild/` folder.

**Building repositories from GitHub**

- https://cloud.google.com/build/docs/automating-builds/build-repos-from-github

# Repository Settings

## GCP Resources Terraform Settings

- GCP project settings and feature flags (`terraform/gcp/google_project_id.tfvars`)
- GCP general (`terraform/gcp/gcp-settings.tf`)
- Cloud Build configuration (`terraform/gcp/cloudbuild-settings.tf`)
- HashiCorp Vault resources (`terraform/gcp/vault-settings.tf`)

GCP project settings (`terraform/gcp/google_project_id.tfvars`) keep differences between deployment environments (dev, prod, etc.) and control GCP project feature flags (enable/disable GKE deployment, etc)

# Google Cloud Bash Functions

**Show last Cloud Build output for us-central1 region**

```bash
gcp-show-cloudbuild-us_central1() {
  local build_id
  gcloud builds list --region=us-central1 --limit=3
  build_id=$(gcloud builds list --region=us-central1 --limit=1 --format="value(id)")
  gcloud builds log --region=us-central1 --stream ${build_id:?}
}
```

**Show last Cloud Build output for Global region**

```bash
gcp-show-cloudbuild-global() {
  local build_id
  gcloud builds list --limit=3
  build_id=$(gcloud builds list --limit=1 --format="value(id)")
  gcloud builds log --stream ${build_id:?}
}
```

# GCP Documentation and General Notes

## Virtual Private Network (VPC)

### VPC Networks Peering Restrictions

Transitive peering is not supported. Only directly peered networks can communicate. In other words, if VPC network N2 peers with N1 and N3, but N1 and N3 are not directly connected, VPC network N1 cannot communicate with VPC network N3 over VPC Network Peering.

```shell
{N1} <=> {N2} <=> {N3}
```

- https://cloud.google.com/vpc/docs/vpc-peering#restrictions

## Kubernetes Clusters (GKE)

### Private GKE Cluster

**Accessing Private GKE from a local workstation using SSH SOCKS5 proxy**

```bash
> gcloud compute ssh ${gke_proxy_instance} --zone=us-central1-a --ssh-flag="-f -n -N -D 127.0.0.1:8080"
> export HTTPS_PROXY=socks5://127.0.0.1:8080

> kubectl cluster-info
Kubernetes control plane is running at https://10.0.0.2
```

**Accessing Private GKE from Cloud Build using SSH SOCKS5 proxy**

```bash
> ssh -o StrictHostKeyChecking=no -f -n -N -D 127.0.0.1:8080 cloudbuild@${gke_proxy_ip_address}
> export HTTPS_PROXY=socks5://127.0.0.1:8080

> kubectl cluster-info
Kubernetes control plane is running at https://10.0.0.2
```
