<!-- @format -->

# About

The Terraform code implements Google Cloud services for HashiCorp Vault deployment.

# Google Cloud Notes

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
