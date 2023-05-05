output "slack_bot_token_secret_id" {
  value = google_secret_manager_secret.slack_bot_token.secret_id
}
output "slack_singing_secret_id" {
  value = google_secret_manager_secret.slack_singing_secret.secret_id
}
output "slack_webhook_url_secret_id" {
  value = google_secret_manager_secret.slack_webhook_url.secret_id
}
output "openai_api_key_secret_id" {
  value = google_secret_manager_secret.openai_api_key.secret_id
}
output "pinecone_api_key_secret_id" {
  value = google_secret_manager_secret.pinecone_api_key.secret_id
}