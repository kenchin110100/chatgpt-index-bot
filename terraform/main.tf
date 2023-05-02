provider "google" {
  project = var.project
  region  = var.region
}

provider "google-beta" {
  project = var.project
  region  = var.region
}

module "subscriber" {
  source        = "./modules/subscriber"
  source_dir    = "../subscriber"
  project       = var.project
  region        = var.region
  project_name  = var.project_name
  slack_webhook_url = var.slack_webhook_url
  channel_name  = var.channel_name
  openai_api_key = var.openai_api_key
  pinecone_api_key = var.pinecone_api_key
  pinecone_environment = var.pinecone_environment
  index_name = var.index_name
}

module "publisher" {
  source        = "./modules/publisher"
  source_dir    = "../publisher"
  project       = var.project
  region        = var.region
  project_name  = var.project_name
  slack_bot_token = var.slack_bot_token
  slack_singing_secret = var.slack_singing_secret
  pubsub_topic_id = module.subscriber.pubsub_topic_id
}