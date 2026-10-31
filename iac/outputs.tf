output "service_a_sa_email" {
  value = google_service_account.service_a.email
}

output "service_b_sa_email" {
  value = google_service_account.service_b.email
}

output "cloud_run_urls" {
  value = {
    for name, service in google_cloud_run_v2_service.microservices :
    name => service.uri
  }
}

output "cloud_build_sa_email" {
  value = google_service_account.cloud_build.email
}

resource "google_artifact_registry_repository_iam_member" "cloud_build_writer" {
  project    = var.project_id
  location   = var.region
  repository = google_artifact_registry_repository.microservices.repository_id

  role   = "roles/artifactregistry.writer"
  member = "serviceAccount:${google_service_account.cloud_build.email}"
}


