<!-- @format -->

# Why?

The objective of this repository is to help prospective employers answer the question, "Does this candidate know his ABCs?"

# About

The project implements Continuous Delivery (CD) of Hashicorp Vault into a private GCP Kubernetes cluster (GKE).

GCP Cloud Build pipeline steps:

- Build GCP infrastructure with Terraform code (VPC, GKE, Vault storage, etc.)
- Deploy HashiCorp Vault with HELM chart
- Configure HashiCorp Vault with Terraform code (auth, policies, mounts, etc.)
- Test HashiCorp Vault GKE failover and RAFT replication
- Test HashiCorp Vault configuration (app_roles, transit, etc.)

# Google Cloud

## Implemented Google Cloud Services

- GCP Kubernetes Engine (GKE)
- GCP Certificate Authority (Root CA)
- GCP Cloud Key Management (KMS)
- GCP Cloud Build (CI/CD)
- GCP Cloud DNS
- GCP Cloud Logging routes
- GCP IAM Custom roles
- GCE OS Patch Policies (automatic weekly OS patching)

Google Cloud detailed documentation: [Google Cloud Readme](docs/google-cloud.md)

# Hashicorp Vault

Hashicorp Vault Kubernetes deployment based on the official Hashicorp Vault HELM chart. (https://www.vaultproject.io/docs/platform/k8s/helm)

I re-wrote the official Hashicorp HELM chart to narrow the deployment scope and simplify the HELM code. The current HELM chart implementation depends on the GCP Terraform code and is not designed as a stand-alone unit.

Changes:

- Kubernetes Services to enable GKE internal load-balancer
- Kubernetes Services publishNotReadyAddresses to enable predictable failover
- Kubernetes Secrets to allow TLS certificate automated deployment
- Kubernetes Workload Identity to allow key-less Auto-Unseal operations
- Kubernetes PersistentVolume to allow consistent attachment Vault data GCP Persistent Disks (GCP Snapshot Policy)

HashiCorp Vault detailed documentation: [HashiCorp Vault Readme](docs/hashicorp-vault.md)

# Deployment Environments

The repository structure assumes the deployment target is a single GCP project. All deployment environments (GCP Projects) build from the same code.

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

# Repository Settings

## GCP Resources Terraform Settings

- GCP project settings and feature flags (`terraform/gcp/google_project_id.tfvars`)
- GCP general (`terraform/gcp/gcp-settings.tf`)
- Cloud Build configuration (`terraform/gcp/cloudbuild-settings.tf`)
- HashiCorp Vault resources (`terraform/gcp/vault-settings.tf`)

GCP project settings (`terraform/gcp/google_project_id.tfvars`) keep differences between deployment environments (dev, prod, etc.) and control GCP project feature flags (enable/disable GKE deployment, etc)
