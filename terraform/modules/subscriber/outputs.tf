output "subscriber_endpoint_url" {
  value = google_cloud_run_v2_service.subscriber.uri
}