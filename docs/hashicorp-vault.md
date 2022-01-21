<!-- @format -->

# About

The repository section implements Hashicorp Vault deployment and configuration.

# Vault AppRoles

**Configured AppRoles**

| approle_name | role_id                              | role_secret_id (google_secret_name) |
| ------------ | ------------------------------------ | ----------------------------------- |
| test1        | af69b20d-8292-2227-8296-8514cc8cb4f0 | vault1-approle-test1                |
| test2        | a800ee8f-8379-cb8f-bf6a-b0fdca895549 | vault1-approle-test2                |

`approle_secret_id` automatically stored in Google Secret Manager.

## AppRole Login

### Get `role_secret_id` from Google Secret Manager

- List available secrets

```bash
> gcloud secrets list --project=${google_project}
```

- Get latest secret version

```bash
> secret_version=$(gcloud secrets versions list "${google_secret_name}" --sort-by=name --limit=1 --format="value(name)")
> gcloud secrets versions access --secret="${google_secret_name}" "${secret_version}"
```

- Login into Vault as AppRole

```bash
> VAULT_TOKEN=$(vault write auth/approle/login role_id=${role_id} secret_id=${role_secret_id} -format=json | jq -r ".auth.client_token")
> export VAULT_TOKEN
```

See `scripts/vault-test-approle.sh` script for details.

Vault AppRoles configuration file: `vault/vault-auth-approle.tf`.

# Vault Policies

Vault policies configuration files: `vault/policies/*`.

Vault policies deployment: `vault/vault-policy.tf`.

# Vault Resources (Backend Secrets)

## Vault Transit Keys

Each Vault AppRole assigned one Transit key

```bash
> vault list  transit/keys
Keys
----
test1
test2
```

- Encrypt data

```bash
> vault write "transit/encrypt/test1" plaintext="$(base64 <<<"1234567890")"
Key            Value
---            -----
ciphertext     vault:v1:55M29J8W3SvUktCI9DXTL5VFfyeMJ6SA/qyRWHfEDuBqk+sd8UtP
key_version    1
```

- Decrypt data

```bash
> vault write "transit/decrypt/test1" ciphertext="vault:v1:55M29J8W3SvUktCI9DXTL5VFfyeMJ6SA/qyRWHfEDuBqk+sd8UtP"
Key          Value
---          -----
plaintext    MTIzNDU2Nzg5MAo=

> base64 --decode <<<"MTIzNDU2Nzg5MAo="
1234567890
```

# Vault Audit Logs

## HashiCorp Documentation

Troubleshooting Vault: https://learn.hashicorp.com/tutorials/vault/troubleshooting-vault

Querying Audit Device Logs: https://learn.hashicorp.com/tutorials/vault/query-audit-device-logs

Audit Devices: https://www.vaultproject.io/docs/audit

## Sensitive Information

The audit logs contain the complete request and response objects for every interaction with Vault. Most strings within requests and responses are hashed using HMAC-SHA256. The purpose of the hash is to mask plaintext-sensitive information within audit logs. HMAC-SHA256 hashes can be unmasked. https://learn.hashicorp.com/tutorials/vault/query-audit-device-logs?in=vault/monitoring#hmac-hash-calculation-example

## Enable Audit Logs for Kubernetes

Vault is a contemporary server application designed to align well with paradigms such as the Twelve-Factor App and contemporary operating system features like journald. Vault logs details about its internal operation and subsystem to standard output and standard error.

Google GKE will automatically route all stdout and stderr to Cloud Logging for analysis.

**Enable Audit logs**

```bash
> vault audit enable file file_path=stdout
```

## Disable Audit Logs

**List Audit logs**

```bash
> vault audit list -detailed
Path     Type    Description    Replication    Options
----     ----    -----------    -----------    -------
file/    file    n/a            replicated     file_path=stdout

```

**Disable Audit logs**

```bash
> vault audit disable file/
```

## Analyze Audit Logs

Logs from Vault Kubernetes pods can be retrieved with the kubectl logs command.

**Identify Active Vault pod**

```bash
> kubectl -n vaultqss1 get pod --selector vault-active=true
NAME          READY   STATUS    RESTARTS   AGE
vaultqss1-0   1/1     Running   0          18m
```

**View Vault logs with kubectl**

```bash
> kubectl -n vaultqss1 logs vaultqss1-0 | tail --lines=1 | jq
{
  "time": "2022-01-13T19:27:00.594173635Z",
  "type": "response",
  "auth": {
    "client_token": "hmac-sha256:5de17a370db5b82a3108d1cede3e1ebcf04920885af0b23eb4bb8cab9cf199e4",
    "accessor": "hmac-sha256:11376dc841da0c8e7b50efb9f73b0719f0fd3d427e675ff6733c4c87e730a9ce",
    "display_name": "approle",
    "policies": [
      "default",
      "hwapp",
      "vault-client"
    ],
    "token_policies": [
      "default",
      "hwapp",
      "vault-client"
    ],
    "metadata": {
      "role_name": "hwapp"
    },
    "entity_id": "fb3e9a7d-e8a3-96da-d1e0-348622d71a3a",
    "token_type": "service",
    "token_ttl": 86400,
    "token_issue_time": "2022-01-13T19:26:56Z"
  },
  "request": {
    "id": "adc24b63-a11c-21ea-1c3c-b96b99d7465d",
    "operation": "update",
    "mount_type": "transit",
    "client_token": "hmac-sha256:5de17a370db5b82a3108d1cede3e1ebcf04920885af0b23eb4bb8cab9cf199e4",
    "client_token_accessor": "hmac-sha256:11376dc841da0c8e7b50efb9f73b0719f0fd3d427e675ff6733c4c87e730a9ce",
    "namespace": {
      "id": "root"
    },
    "path": "transit/decrypt/test1",
    "data": {
      "ciphertext": "hmac-sha256:56691b97f2abe696536367ebf4b14a0e831c56ed55ef96b4aeb47d864ac8397e"
    },
    "remote_address": "10.9.187.252"
  },
  "response": {
    "mount_type": "transit",
    "data": {
      "error": "hmac-sha256:0163ce99e1e95723836da8547bc7195101017724d990cdaf743587ba6f7c3157"
    }
  },
  "error": "1 error occurred:\n\t* permission denied\n\n"
}

```

**View Vault logs with Google CLI**

```bash
> gcloud logging read --limit=1 '
resource.type="k8s_container"
resource.labels.namespace_name="vaultqss1"
resource.labels.container_name="vault"
jsonPayload.error="1 error occurred:\n\t* permission denied\n\n"
jsonPayload.type="response"
'
---
insertId: r1ghxeozllzvdn3c
jsonPayload:
  auth:
    accessor: hmac-sha256:07f2c51c7fd4f4f173d6cb5db30a242d5422a7dc2b709d70c258523af26f92cd
    client_token: hmac-sha256:eff8e54a66455b7123c010d3c8980fab5537a9b6b0b4a38c7219a02317ce2c4e
    display_name: approle
    entity_id: dbd65be7-a643-1e31-cc80-f0217ce6902a
    metadata:
      role_name: merchant
    policies:
    - default
    - merchant
    - vault-client
    token_issue_time: '2022-01-14T15:35:53Z'
    token_policies:
    - default
    - merchant
    - vault-client
    token_ttl: 86400
    token_type: service
  error: |+
    1 error occurred:
    	* permission denied

  request:
    client_token: hmac-sha256:eff8e54a66455b7123c010d3c8980fab5537a9b6b0b4a38c7219a02317ce2c4e
    client_token_accessor: hmac-sha256:07f2c51c7fd4f4f173d6cb5db30a242d5422a7dc2b709d70c258523af26f92cd
    data:
      ciphertext: hmac-sha256:56691b97f2abe696536367ebf4b14a0e831c56ed55ef96b4aeb47d864ac8397e
    id: 7b3e6a0d-1414-94ca-b63b-aa6cb94c3d7b
    mount_type: transit
    namespace:
      id: root
    operation: update
    path: transit/decrypt/test1
    remote_address: 10.9.187.253
  response:
    data:
      error: hmac-sha256:0163ce99e1e95723836da8547bc7195101017724d990cdaf743587ba6f7c3157
    mount_type: transit
  type: response
labels:
  compute.googleapis.com/resource_name: gke-gcp-usw2-gke-qss-vlt-01-pool1-1-94097757-97vf
  k8s-pod/app_kubernetes_io/instance: vaultqss1
  k8s-pod/app_kubernetes_io/managed-by: Helm
  k8s-pod/app_kubernetes_io/name: vault
  k8s-pod/app_kubernetes_io/version: 1.9.2
  k8s-pod/controller-revision-hash: vaultqss1-586c9fd955
  k8s-pod/helm_sh/chart: vault-1.0.3
  k8s-pod/statefulset_kubernetes_io/pod-name: vaultqss1-1
  k8s-pod/vault-active: 'true'
  k8s-pod/vault-initialized: 'true'
  k8s-pod/vault-perf-standby: 'false'
  k8s-pod/vault-sealed: 'false'
  k8s-pod/vault-version: 1.9.2
logName: projects/lab5-k8s-d1/logs/stdout
receiveTimestamp: '2022-01-14T15:35:57.585928428Z'
resource:
  labels:
    cluster_name: gcp-usw2-gke-qss-vlt-01
    container_name: vault
    location: us-west2
    namespace_name: vaultqss1
    pod_name: vaultqss1-1
    project_id: lab5-k8s-d1
  type: k8s_container
severity: INFO
timestamp: '2022-01-14T15:35:54.480066912Z'
```
