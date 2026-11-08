resource "google_cloudbuildv2_connection" "github" {
  project  = var.project_id
  location = var.region
  name     = "github-connection"

  github_config {
    app_installation_id = 177732407

    authorizer_credential {
      oauth_token_secret_version = "projects/${var.project_id}/locations/${var.region}/secrets/github-connection-github-oauthtoken-f6c13d/versions/latest"
    }
  }
}

resource "google_cloudbuildv2_repository" "microservices" {
  project           = var.project_id
  location          = var.region
  name              = "fast-api-microservices"
  parent_connection = google_cloudbuildv2_connection.github.id
  remote_uri        = "https://github.com/Danavarro19/fast-api-microservices.git"
}

resource "google_cloudbuild_trigger" "services" {
  for_each = local.services

  project         = var.project_id
  location        = var.region
  name            = "${each.key}-main"
  filename        = "cloudbuild.yaml"
  service_account = google_service_account.cloud_build.name

  included_files = [
    "services/${each.key}/**",
    "cloudbuild.yaml"
  ]

  repository_event_config {
    repository = google_cloudbuildv2_repository.microservices.id

    push {
      branch = "^main$"
    }
  }

  substitutions = {
    _REGION     = var.region
    _REPOSITORY = google_artifact_registry_repository.microservices.repository_id
    _SERVICES   = each.key
  }
}
