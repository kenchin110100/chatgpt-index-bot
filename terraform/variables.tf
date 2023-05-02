variable "project" {}
variable "region" {
  default = "asia-northeast1"
}
variable "project_name" {
  default = "chatgpt-index-bot"
}
variable "slack_bot_token" {}
variable "slack_singing_secret" {}
variable "slack_webhook_url" {}
variable "channel_name" {
  default = "#chatgpt-bot-yomoyama"
}
variable "openai_api_key" {}
variable "pinecone_api_key" {}
variable "pinecone_environment" {}
variable "index_name" {}