resource "null_resource" "make_requirements" {
  triggers = {
    requirements_sha1 = "${sha1(file("${var.source_dir}/pyproject.toml"))}"
  }
  provisioner "local-exec" {
    command = "cd ${var.source_dir} && poetry export -f requirements.txt --output requirements.txt --without-hashes;"
  }
}

data "archive_file" "zip" {
  type        = "zip"
  output_path = "${var.source_dir}/dist/source.zip"

  source {
    content  = file("${var.source_dir}/requirements.txt")
    filename = "requirements.txt"
  }

  source {
    content  = file("${var.source_dir}/src/main.py")
    filename = "main.py"
  }
  depends_on = [
    null_resource.make_requirements
  ]
}

# Upload source code
resource "google_storage_bucket_object" "archive" {
  # Append file MD5 to force bucket to be recreated
  name   = "terraform/cloud_functions_source/source-${data.archive_file.zip.output_md5}.zip"
  bucket = "chatgpt-index-bot"
  source = data.archive_file.zip.output_path
}

# Deploy cloud functions
resource "google_cloudfunctions2_function" "function" {
  project               = var.project
  location              = var.region
  name                  = "${var.project_name}-publisher"

  build_config {
    runtime = "python311"
    entry_point = "slack_bot"
    source {
      storage_source {
        bucket = google_storage_bucket_object.archive.bucket
        object = google_storage_bucket_object.archive.name
      }
    }
  }

  service_config {
    available_memory = "512M"
    timeout_seconds  = 540
    # コールドスタート問題に対応
    min_instance_count = 1

    service_account_email = var.publisher_runner_email

    environment_variables = {
      SLACK_BOT_TOKEN_SECRET_ID  = var.slack_bot_token_secret_id
      SLACK_SINGING_SECRET_ID    = var.slack_singing_secret_id
      PROJECT_ID                 = var.project
      TOPIC_ID                   = var.pubsub_topic_id
    }
  }
}

# cloud fuctions v2 の裏側はcloud run v1で動いているので、cloud runにallUserのinvokerを付与する
resource "google_cloud_run_service_iam_member" "invoker" {
  project        = google_cloudfunctions2_function.function.project
  location       = google_cloudfunctions2_function.function.location
  service        = google_cloudfunctions2_function.function.name

  role   = "roles/run.invoker"
  member = "allUsers"
}