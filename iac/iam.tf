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
