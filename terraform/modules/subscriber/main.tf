data "google_project" "project" {}

data "archive_file" "zip" {
  type        = "zip"
  source_dir  = "${var.source_dir}/"
  excludes = [
	"${var.source_dir}/.venv",
	"${var.source_dir}/.vscode",
	"${var.source_dir}/dist",
	"${var.source_dir}/src/__pycache__",
	"${var.source_dir}/.env",
	"${var.source_dir}/.venv"
  ]
  output_path = "${var.source_dir}/dist/source.zip"
}

resource "null_resource" "cloud_build_deploy" {
  triggers = {
    script_hash = data.archive_file.zip.output_md5
  }

  provisioner "local-exec" {
    command = "cd ${var.source_dir} && gcloud builds submit --tag gcr.io/${var.project}/${var.project_name}-subscriber"
  }
  
  depends_on = [data.archive_file.zip]
}

resource "google_cloud_run_service" "subscriber" {
  name     = "${var.project_name}-subscriber"
  location = var.region

  template {
    spec {
      containers {
        image = "gcr.io/${var.project}/${var.project_name}-subscriber"

	env {
	  name = "PROJECT_ID"
	  value = var.project
        }

        env {
	  name = "SLACK_WEBHOOK_URL_SECRET_ID"
	  value = google_secret_manager_secret.slack_webhook_url.secret_id
        }
        env {
	  name = "CHANNEL_NAME"
	  value = var.channel_name
        }
        env {
	  name = "USERNAME"
	  value = var.project_name
        }
	env {
	  name = "OPENAI_API_KEY_SECRET_ID"
	  value = google_secret_manager_secret.openai_api_key.secret_id
        }
	env {
	  name = "PINECONE_API_KEY_SECRET_ID"
	  value = google_secret_manager_secret.pinecone_api_key.secret_id
        }
	env {
	  name = "PINECONE_ENVIRONMENT"
	  value = var.pinecone_environment
        }
	env {
	  name = "INDEX_NAME"
	  value = var.index_name
        }
	env {
	  name = "SOURCE_CODE_HASH"
	  value = data.archive_file.zip.output_md5
        }
      }
    }
  }
  depends_on = [
    null_resource.cloud_build_deploy
  ]
}

resource "google_pubsub_topic" "default" {
  name = "${var.project_name}-pubsub-topic"
}

resource "google_service_account" "sa" {
  account_id   = "cloud-run-pubsub-invoker"
  display_name = "Cloud Run Pub/Sub Invoker"
}

resource "google_cloud_run_service_iam_binding" "binding" {
  location = google_cloud_run_service.subscriber.location
  service  = google_cloud_run_service.subscriber.name
  role     = "roles/run.invoker"
  members  = ["serviceAccount:${google_service_account.sa.email}"]
}

resource "google_project_service_identity" "pubsub_agent" {
  provider = google-beta
  project  = var.project
  service  = "pubsub.googleapis.com"
}

resource "google_project_iam_binding" "project_token_creator" {
  project = var.project
  role    = "roles/iam.serviceAccountTokenCreator"
  members = ["serviceAccount:${google_project_service_identity.pubsub_agent.email}"]
}

resource "google_pubsub_subscription" "subscription" {
  name  = "pubsub_subscription"
  topic = google_pubsub_topic.default.name

  ack_deadline_seconds       = 600
  message_retention_duration = "600s"

  push_config {
    push_endpoint = google_cloud_run_service.subscriber.status.0.url
    oidc_token {
      service_account_email = google_service_account.sa.email
    }
    attributes = {
      x-goog-version = "v1"
    }
  }
  depends_on = [google_cloud_run_service.subscriber]
}

# secret
resource "google_secret_manager_secret" "slack_webhook_url" {
  secret_id = "SLACK_WEBHOOK_URL_SECRET_ID"
  replication {
    automatic = true
  }
  lifecycle {
    prevent_destroy = true
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
    prevent_destroy = true
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
    prevent_destroy = true
  }
}

resource "google_secret_manager_secret_version" "pinecone_api_key_version" {
  secret = google_secret_manager_secret.pinecone_api_key.id
  secret_data = var.pinecone_api_key
}

# Secret Managerの権限付与
resource "google_project_iam_member" "secret_manager_account" {
  project = var.project
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}