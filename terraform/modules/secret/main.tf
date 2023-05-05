# secret
resource "google_secret_manager_secret" "slack_bot_token" {
  secret_id = "SLACK_BOT_TOKEN_SECRET_ID"
  replication {
    automatic = true
  }
  lifecycle {
    prevent_destroy = false
  }
}

resource "google_secret_manager_secret_version" "slack_bot_token_version" {
  secret = google_secret_manager_secret.slack_bot_token.id
  secret_data = var.slack_bot_token
}

resource "google_secret_manager_secret" "slack_singing_secret" {
  secret_id = "SLACK_SINGING_SECRET_ID"
  replication {
    automatic = true
  }
  lifecycle {
    prevent_destroy = false
  }
}

resource "google_secret_manager_secret_version" "slack_singing_secret_version" {
  secret = google_secret_manager_secret.slack_singing_secret.id
  secret_data = var.slack_singing_secret
}

# secret
resource "google_secret_manager_secret" "slack_webhook_url" {
  secret_id = "SLACK_WEBHOOK_URL_SECRET_ID"
  replication {
    automatic = true
  }
  lifecycle {
    prevent_destroy = false
  }
}

resource "google_secret_manager_secret_version" "slack_webhook_url_version" {
  secret = google_secret_manager_secret.slack_webhook_url.id
  secret_data = var.slack_webhook_url
}

resource "google_secret_manager_secret" "openai_api_key" {
  secret_id = "OPENAI_API_KEY_SECRET_ID"
  replication {
    automatic = true
  }
  lifecycle {
    prevent_destroy = false
  }
}

resource "google_secret_manager_secret_version" "openai_api_key_version" {
  secret = google_secret_manager_secret.openai_api_key.id
  secret_data = var.openai_api_key
}

resource "google_secret_manager_secret" "pinecone_api_key" {
  secret_id = "PINECONE_API_KEY_SECRET_ID"
  replication {
    automatic = true
  }
  lifecycle {
    prevent_destroy = false
  }
}

resource "google_secret_manager_secret_version" "pinecone_api_key_version" {
  secret = google_secret_manager_secret.pinecone_api_key.id
  secret_data = var.pinecone_api_key
}