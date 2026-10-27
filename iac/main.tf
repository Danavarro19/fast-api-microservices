locals {
  required_apis = [
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "iam.googleapis.com"
  ]
}


resource "google_project_service" "required_apis" {
  for_each = toset(local.required_apis)

  project = var.project_id
  service = each.value

  disable_on_destroy = false
}

resource "google_artifact_registry_repository" "microservices" {
  project       = var.project_id
  location      = var.region
  repository_id = "microservices"
  description   = "Docher images for FastAPI microservices"
  format        = "DOCKER"

  depends_on = [
    google_project_service.required_apis
  ]
}

