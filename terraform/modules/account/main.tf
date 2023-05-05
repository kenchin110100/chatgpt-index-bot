# ===== cloudfunctionsのランタイム用サービスアカウントの設定 =====
# https://cloud.google.com/functions/docs/concepts/iam?hl=ja
# cloudfunctionsランタイム用のサービスアカウントを作成する
resource "google_service_account" "publisher_runner" {
  account_id   = "publisher-runner"
  display_name = "${var.project_name}のpublisherを実行するサービスアカウント"
}

# cloudfunctionsの実行アカウントへSecret Managerの権限付与
resource "google_project_iam_member" "publisher_secret_manager" {
  project = var.project
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.publisher_runner.email}"
}

# cloudfunctionsの実行アカウントへpubsubへのpublish権限を付与
resource "google_project_iam_member" "publisher_pubsub_publisher" {
  project = var.project
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.publisher_runner.email}"
}

# ===== ここまでがcloudfunctionsランタイムアカウントの設定 =====

# ===== cloudrunのランタイム用サービスアカウントの設定 =====
resource "google_service_account" "subscriber_runner" {
  account_id = "subscriber-runner"
  display_name = "${var.project_name}のsubscriberを実行するサービスアカウント"
}

# cloudrunの実行アカウントへSecret Mangerの権限を付与
resource "google_project_iam_member" "subscriber_secret_manager" {
  project = var.project
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.subscriber_runner.email}"
}

# ===== ここまでがcloudrunランタイムアカウントの設定 =====

# ===== ここからがpubsub関連のアカウント設定 =====

# PubSub関連のサービスアカウント設定
# Pub/Sub サブスクリプションの ID を表すサービス アカウントを作成または選択
resource "google_service_account" "pubsub_invoker" {
  account_id   = "cloud-run-pubsub-invoker"
  display_name = "${var.project_name}でpubsubからcloudrunを実行するためのサービスアカウント"
}

# 作成したサービスアカウントに、cloudrunを呼び出す権限を付与 -> これはsubscriberの設定に記載
# resource "google_cloud_run_service_iam_binding" "binding" {
#   location = google_cloud_run_service.default.location
#   service  = google_cloud_run_service.default.name
#   role     = "roles/run.invoker"
#   members  = ["serviceAccount:${google_service_account.sa.email}"]
# }

# pubsubがproject内で認証トークンを作成できるようにする
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