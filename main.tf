data "google_iam_policy" "serviceagent_secretAccessor" {
  binding {
    role    = "roles/secretmanager.secretAccessor"
    members = ["serviceAccount:service-${var.project_number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"]
  }
}

resource "google_secret_manager_secret_iam_policy" "policy" {
  project     = var.project
  secret_id   = var.deploy_key_id
  policy_data = data.google_iam_policy.serviceagent_secretAccessor.policy_data
}

// Create the GitHub connection
resource "google_cloudbuildv2_connection" "connection" {
  project  = var.project
  location = var.region
  name     = var.connection_name

  github_config {
    app_installation_id = var.installation_id
    authorizer_credential {
      oauth_token_secret_version = "projects/${var.project_number}/secrets/${var.deploy_key_id}/versions/${var.deploy_key_version}"
    }
  }
  depends_on = [google_secret_manager_secret_iam_policy.policy]
}

resource "google_cloudbuildv2_repository" "repository" {
  for_each          = var.repos
  project           = var.project
  location          = var.region
  name              = each.value
  parent_connection = google_cloudbuildv2_connection.connection.name
  remote_uri        = "https://github.com/${var.repo_owner}/${each.value}.git"
}

resource "google_cloudbuild_trigger" "repo_trigger" {
  for_each = google_cloudbuildv2_repository.repository
  location = var.region
  name     = each.key

  repository_event_config {
    repository = each.value.id
    push {
      branch = "^${var.default_branch}$"
    }
  }

  filename = "config/cloudbuild.yaml"
}
