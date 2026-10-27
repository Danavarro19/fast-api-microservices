output "service_a_sa_email" {
  value = google_service_account.service_a.email
}

output "service_b_sa_email" {
  value = google_service_account.service_b.email
}
