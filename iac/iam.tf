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

  service_account_id = google_service_account.service_a.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.cloud_build.email}"
}


