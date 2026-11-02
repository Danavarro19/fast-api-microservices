resource "google_service_account" "service_a" {
  project      = var.project_id
  account_id   = "service-a-sa"
  display_name = "Service A runtime"
}

resource "google_service_account" "service_b" {
  project      = var.project_id
  account_id   = "service-b-sa"
  display_name = "Service B runtime"
}

resource "google_service_account" "cloud_build" {
  project      = var.project_id
  account_id   = "cloud-build-sa"
  display_name = "Cloud Build CI/CD"
  description  = "Builds Docker images and deploys Cloud Run Services"
}


resource "google_cloud_run_v2_service_iam_member" "cloud_build_developer" {
  for_each = google_cloud_run_v2_service.microservices

  project  = var.project_id
  location = var.region
  name     = each.value.name

  role   = "roles/run.developer"
  member = "serviceAccount:${google_service_account.cloud_build.email}"
}


resource "google_service_account_iam_member" "cloud_build_runtime_user" {
  for_each = local.services

  service_account_id = each.value.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.cloud_build.email}"
}

resource "google_project_iam_member" "cloud_build_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.cloud_build.email}"
}

resource "google_artifact_registry_repository_iam_member" "cloud_build_writer" {
  project    = var.project_id
  location   = var.region
  repository = google_artifact_registry_repository.microservices.repository_id

  role   = "roles/artifactregistry.writer"
  member = "serviceAccount:${google_service_account.cloud_build.email}"
}

# Read source archives in gcloud storage bucket (For manual executions)
resource "google_storage_bucket_iam_member" "cloud_build_source_reader" {
  bucket = "${var.project_id}_cloudbuild"
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.cloud_build.email}"
}

resource "google_cloud_run_v2_service_iam_member" "public_access" {
  for_each = google_cloud_run_v2_service.microservices

  project  = var.project_id
  location = var.region
  name     = each.value.name

  role   = "roles/run.invoker"
  member = "allUsers"
}
