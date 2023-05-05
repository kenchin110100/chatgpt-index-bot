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
	  value = var.slack_webhook_url_secret_id
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
	  value = var.openai_api_key_secret_id
        }
	env {
	  name = "PINECONE_API_KEY_SECRET_ID"
	  value = var.pinecone_api_key_secret_id
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

resource "google_cloud_run_service_iam_binding" "binding" {
  location = google_cloud_run_service.subscriber.location
  service  = google_cloud_run_service.subscriber.name
  role     = "roles/run.invoker"
  members  = ["serviceAccount:${var.pubsub_sa_email}"]
}