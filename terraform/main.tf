provider "google" {
  project = var.project
  region  = var.region
}

provider "google-beta" {
  project = var.project
  region  = var.region
}

module "secret" {
  source                = "./modules/secret"
  slack_bot_token       = var.slack_bot_token
  slack_singing_secret  = var.slack_singing_secret
  slack_webhook_url     = var.slack_webhook_url
  openai_api_key        = var.openai_api_key
  pinecone_api_key      = var.pinecone_api_key
}

module "subscriber" {
  source                      = "./modules/subscriber"
  source_dir                  = "../subscriber"
  project                     = var.project
  region                      = var.region
  project_name                = var.project_name
  slack_webhook_url_secret_id = module.secret.slack_webhook_url_secret_id
  channel_name                = var.channel_name
  openai_api_key_secret_id    = module.secret.openai_api_key_secret_id
  pinecone_api_key_secret_id  = module.secret.pinecone_api_key_secret_id
  pinecone_environment        = var.pinecone_environment
  index_name                  = var.index_name
}

module "publisher" {
  source                    = "./modules/publisher"
  source_dir                = "../publisher"
  project                   = var.project
  region                    = var.region
  project_name              = var.project_name
  slack_bot_token_secret_id = module.secret.slack_bot_token_secret_id
  slack_singing_secret_id   = module.secret.slack_singing_secret_id
  pubsub_topic_id           = module.subscriber.pubsub_topic_id
}