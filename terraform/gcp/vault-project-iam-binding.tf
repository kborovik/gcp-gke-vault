/*

Show Service Account project roles:

  gcloud projects get-iam-policy  --flatten='bindings[].members' --format='table(bindings.role)' --filter='bindings.members=serviceAccount:<service_account>' <project_id>

*/

/*

Assign custom role to Vault SA

*/
resource "google_project_iam_binding" "vault_server" {
  project = var.project_id
  role    = google_project_iam_custom_role.vault_server.name

  members = [
    "serviceAccount:${google_service_account.vault.email}",
  ]
}
