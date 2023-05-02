data "google_project" "project" {
  provider = google-beta
}

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
	  name = "SLACK_WEBHOOK_URL"
	  value = var.slack_webhook_url
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
	  name = "OPENAI_API_KEY"
	  value = var.openai_api_key
        }
	env {
	  name = "PINECONE_API_KEY"
	  value = var.pinecone_api_key
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