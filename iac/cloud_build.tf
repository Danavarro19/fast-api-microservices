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
