terraform {
  backend "gcs" {
    bucket = "chatgpt-index-bot"
    prefix = "terraform/state"
  }
}

resource "google_storage_bucket" "terraform-state-store" {
  name     = "chatgpt-index-bot"
  location = "asia-northeast1"
  storage_class = "REGIONAL"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      num_newer_versions = 5
    }
  }
}