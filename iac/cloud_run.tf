locals {
  services = {
    service-a = google_service_account.service_a.email
    service-b = google_service_account.service_b.email
  }
}


resource "google_cloud_run_v2_service" "microservices" {
  for_each = local.services

  project  = var.project_id
  name     = each.key
  location = var.region

  deletion_protection = false
  ingress             = "INGRESS_TRAFFIC_ALL"

  lifecycle {
    ignore_changes = [
      template[0].containers[0].image
    ]
  }

  template {
    service_account = each.value

    scaling {
      min_instance_count = 0
      max_instance_count = 1
    }

    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/microservices/${each.key}:v1"

      ports {
        container_port = 8080
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }

        cpu_idle = true

      }
    }
  }

  depends_on = [
    google_project_service.required_apis
  ]
}

resource "google_cloud_run_v2_service_iam_member" "public_access" {
  for_each = google_cloud_run_v2_service.microservices

  project  = var.project_id
  location = var.region
  name     = each.value.name

  role   = "roles/run.invoker"
  member = "allUsers"
}
