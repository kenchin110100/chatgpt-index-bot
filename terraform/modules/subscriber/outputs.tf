output "subscriber_endpoint_url" {
  value = google_cloud_run_service.subscriber.status.0.url
}
output "pubsub_sa_email" {
  value = google_service_account.sa.email
}