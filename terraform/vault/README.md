<!-- @format -->

# About

The repository section implements Hashicorp Vault deployment and configuration.

# How to Deploy

## Hashicorp Vault Deployment

**Test Vault configuration**

```bash
> cd <git_repository_root>
> ./scripts/vault-setup.sh -p <google_project> -d <vault_dns_name>
```

**Apply Vault configuration**

```bash
> cd <git_repository_root>
> ./scripts/vault-setup.sh -p <google_project> -d <vault_dns_name> -a
```

## Hashicorp Vault Deployment Tests

**Test Vault AppRoles and Policies**

```bash
> cd <git_repository_root>
> ./scripts/vault-test-approle.sh -p <google_project> -d <vault_dns_name> -r <approle>
```

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
