output "subscriber_endpoint_url" {
  value = google_cloud_run_service.subscriber.status.0.url
}