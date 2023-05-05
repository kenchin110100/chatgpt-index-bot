output "pubsub_invoker_email" {
  value = google_service_account.pubsub_invoker.email
}
output "publisher_runner_email" {
  value = google_service_account.publisher_runner.email
}
output "subscriber_runner_email" {
  value = google_service_account.subscriber_runner.email
}