# Add Artifact Registry Reader policy
data "google_iam_policy" "artifact_registry_reader" {
  binding {
    role = "roles/artifactregistry.reader"
    members = [
      "serviceAccount:${var.project_number}@cloudbuild.gserviceaccount.com",
      "serviceAccount:service-${var.project_number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
    ]
  }
}

# Apply the policy to the Artifact Registry repository
resource "google_artifact_registry_repository_iam_policy" "docker_policy" {
  project     = var.project
  location    = var.region
  repository  = "docker"
  policy_data = data.google_iam_policy.artifact_registry_reader.policy_data
}

data "google_iam_policy" "secretAccessor" {
  binding {
    role = "roles/secretmanager.secretAccessor"
    members = [
      "serviceAccount:service-${var.project_number}@gcp-sa-cloudbuild.iam.gserviceaccount.com",
      "serviceAccount:${var.project_number}@cloudbuild.gserviceaccount.com"
    ]
  }
}

resource "google_secret_manager_secret_iam_policy" "policy" {
  project     = var.project
  secret_id   = var.deploy_key_id
  policy_data = data.google_iam_policy.secretAccessor.policy_data
}

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
  for_each          = { for repo in var.repos : repo.name => repo }
  project           = var.project
  location          = var.region
  name              = each.key
  parent_connection = google_cloudbuildv2_connection.connection.name
  remote_uri        = "https://github.com/${var.repo_owner}/${each.key}.git"
}

# Add Storage Admin role to Cloud Build service accounts
resource "google_project_iam_member" "cloudbuild_storage_admin" {
  project = var.project
  role    = "roles/storage.admin"
  member  = "serviceAccount:${var.project_number}@cloudbuild.gserviceaccount.com"
}

resource "google_project_iam_member" "cloudbuild_service_storage_admin" {
  project = var.project
  role    = "roles/storage.admin"
  member  = "serviceAccount:service-${var.project_number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
}

# Add Compute Admin role to Cloud Build service accounts
resource "google_project_iam_member" "cloudbuild_compute_admin" {
  project = var.project
  role    = "roles/compute.admin"
  member  = "serviceAccount:${var.project_number}@cloudbuild.gserviceaccount.com"
}

# Add compute network admin role for URL maps and SSL certificates
resource "google_project_iam_member" "cloudbuild_network_admin" {
  project = var.project
  role    = "roles/compute.networkAdmin"
  member  = "serviceAccount:${var.project_number}@cloudbuild.gserviceaccount.com"
}

# Add security admin role for SSL certificates
resource "google_project_iam_member" "cloudbuild_security_admin" {
  project = var.project
  role    = "roles/compute.securityAdmin"
  member  = "serviceAccount:${var.project_number}@cloudbuild.gserviceaccount.com"
}

# Add DNS Administrator role to Cloud Build service account
resource "google_project_iam_member" "cloudbuild_dns_admin" {
  project = var.project
  role    = "roles/dns.admin"
  member  = "serviceAccount:${var.project_number}@cloudbuild.gserviceaccount.com"
}

# You might also need it for the cloudbuild service account
resource "google_project_iam_member" "cloudbuild_service_dns_admin" {
  project = var.project
  role    = "roles/dns.admin"
  member  = "serviceAccount:service-${var.project_number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
}

# Add Service Account Admin role to Cloud Build service accounts
resource "google_project_iam_member" "cloudbuild_service_account_admin" {
  project = var.project
  role    = "roles/iam.serviceAccountAdmin"
  member  = "serviceAccount:${var.project_number}@cloudbuild.gserviceaccount.com"
}

resource "google_project_iam_member" "cloudbuild_service_account_admin_service" {
  project = var.project
  role    = "roles/iam.serviceAccountAdmin"
  member  = "serviceAccount:service-${var.project_number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
}

# Add Service Account User role to Cloud Build service accounts
resource "google_project_iam_member" "cloudbuild_service_account_user" {
  project = var.project
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${var.project_number}@cloudbuild.gserviceaccount.com"
}

resource "google_project_iam_member" "cloudbuild_service_account_user_service" {
  project = var.project
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:service-${var.project_number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
}

# Add Cloud Functions Admin role to Cloud Build service accounts
resource "google_project_iam_member" "cloudbuild_functions_admin" {
  project = var.project
  role    = "roles/cloudfunctions.admin"
  member  = "serviceAccount:${var.project_number}@cloudbuild.gserviceaccount.com"
}

resource "google_project_iam_member" "cloudbuild_service_functions_admin" {
  project = var.project
  role    = "roles/cloudfunctions.admin"
  member  = "serviceAccount:service-${var.project_number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
}

resource "google_cloudbuild_trigger" "repo_trigger" {
  for_each = {
    for repo in var.repos :
    repo.name => repo
    if lookup(repo, "pr_trigger", true)
  }

  location = var.region
  name     = each.key

  repository_event_config {
    repository = google_cloudbuildv2_repository.repository[each.key].id
    pull_request {
      branch = "^${var.default_branch}$"
    }
  }

  substitutions = {
    "_PROJECT_ID"     = var.project
    "_REGION"         = var.region
    "_REPO_OWNER"     = var.repo_owner
    "_DEFAULT_BRANCH" = var.default_branch
    "_PR_TYPE"        = "$(body.pull_request.labels[*].name)"
    "_PR_NUMBER"      = "$(body.number)"
  }

  filename = "config/cloudbuild.yaml"
}

resource "google_cloudbuild_trigger" "merge_trigger" {
  for_each = {
    for repo in var.repos :
    repo.name => repo
    if lookup(repo, "push_trigger", true)
  }

  name        = "${each.key}-merge-trigger"
  description = "Trigger for merge to main for ${each.key}"
  location    = var.region

  repository_event_config {
    repository = google_cloudbuildv2_repository.repository[each.key].id
    push {
      branch = "^${var.default_branch}$"
    }
  }

  substitutions = {
    "_PROJECT_ID" = var.project
    "_REGION"     = var.region
    "_REPO_OWNER" = var.repo_owner
    "_PR_TYPE"    = "$(body.after)"
    "_IS_MERGE"   = "true"
    "_PR_NUMBER"  = ""
  }

  filename = "config/cloudbuild.yaml"

  depends_on = [
    google_cloudbuildv2_repository.repository,
    google_cloudbuildv2_connection.connection
  ]
}
