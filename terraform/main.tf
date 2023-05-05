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

module "account" {
  source       = "./modules/account"
  project      = var.project
  project_name = var.project_name
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
  pubsub_invoker_email        = module.account.pubsub_invoker_email
  subscriber_runner_email     = module.account.subscriber_runner_email
}

module "pubsub" {
  source                  = "./modules/pubsub"
  project_name            = var.project_name
  subscriber_endpoint_url = module.subscriber.subscriber_endpoint_url
  pubsub_invoker_email    = module.account.pubsub_invoker_email
}

module "publisher" {
  source                    = "./modules/publisher"
  source_dir                = "../publisher"
  project                   = var.project
  region                    = var.region
  project_name              = var.project_name
  slack_bot_token_secret_id = module.secret.slack_bot_token_secret_id
  slack_singing_secret_id   = module.secret.slack_singing_secret_id
  pubsub_topic_id           = module.pubsub.pubsub_topic_id
  publisher_runner_email    = module.account.publisher_runner_email
}