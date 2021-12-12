/*

Pull-Request based Cloudbuild pipeline

*/
resource "google_cloudbuild_trigger" "pull_request" {
  count       = var.enable_cloudbuild_pull_request == true ? 1 : 0
  name        = "cloudbuild-pr"
  description = "Invokes a build for every pull request commit push"
  filename    = "cloudbuild/cloudbuild.yaml"

  included_files = [
    "cloudbuild/**",
    "kubernetes/**",
    "scripts/**",
    "terraform/**",
  ]

  github {
    owner = "kborovik"
    name  = "gcp-gke-vault"
    pull_request {
      branch          = "^main$"
      comment_control = "COMMENTS_ENABLED_FOR_EXTERNAL_CONTRIBUTORS_ONLY"
    }
  }
}

/*

Main branch Merge based Cloudbuild pipeline

*/
resource "google_cloudbuild_trigger" "push" {
  count       = var.enable_cloudbuild_push == true ? 1 : 0
  name        = "cloudbuild-merge"
  description = "Invokes a build for every Git commit push"
  filename    = "cloudbuild/cloudbuild.yaml"

  github {
    owner = "kborovik"
    name  = "gcp-gke-vault"

    push {
      branch = "^main$"
    }
  }
}

/*

Tag based Cloudbuild pipeline

*/
resource "google_cloudbuild_trigger" "tag" {
  count       = var.enable_cloudbuild_tag == true ? 1 : 0
  name        = "cloudbuild-tag"
  description = "Invokes a build for every Git tag push"
  filename    = "cloudbuild/cloudbuild.yaml"

  github {
    owner = "kborovik"
    name  = "gcp-gke-vault"

    push {
      tag = "^${var.project_id}$"
    }
  }
}
