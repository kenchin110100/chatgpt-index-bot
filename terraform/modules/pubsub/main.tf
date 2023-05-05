resource "google_pubsub_topic" "default" {
  name = "${var.project_name}-pubsub-topic"
}

resource "google_pubsub_subscription" "subscription" {
  name  = "pubsub_subscription"
  topic = google_pubsub_topic.default.name

  ack_deadline_seconds       = 600
  message_retention_duration = "600s"

  push_config {
    push_endpoint = var.subscriber_endpoint_url
    oidc_token {
      service_account_email = var.pubsub_invoker_email
    }
    attributes = {
      x-goog-version = "v1"
    }
  }
}