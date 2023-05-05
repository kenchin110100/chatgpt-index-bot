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
resource "google_cloudfunctions_function" "function" {
  project               = var.project
  region                = var.region
  name                  = "${var.project_name}-publisher"
  runtime               = "python311"

  available_memory_mb   = 512
  source_archive_bucket = google_storage_bucket_object.archive.bucket
  source_archive_object = google_storage_bucket_object.archive.name
  timeout               = 540
  entry_point           = "slack_bot"

  trigger_http          = true

  # コールドスタート問題に対応
  min_instances         = 1

  environment_variables = {
    SLACK_BOT_TOKEN_SECRET_ID  = var.slack_bot_token_secret_id
    SLACK_SINGING_SECRET_ID    = var.slack_singing_secret_id
    PROJECT_ID                 = var.project
    TOPIC_ID                   = var.pubsub_topic_id
  }
}

# IAM entry for all users to invoke the function
resource "google_cloudfunctions_function_iam_member" "invoker" {
  project        = google_cloudfunctions_function.function.project
  region         = google_cloudfunctions_function.function.region
  cloud_function = google_cloudfunctions_function.function.name

  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}