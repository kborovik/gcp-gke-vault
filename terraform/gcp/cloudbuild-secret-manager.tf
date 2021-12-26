/*

SSH Key 

*/
resource "google_secret_manager_secret" "ssh_key_cloudbuild" {
  secret_id = "cloudbuild-ssh-key"

  replication {
    automatic = true
  }

  lifecycle {
    prevent_destroy = true
  }
}
