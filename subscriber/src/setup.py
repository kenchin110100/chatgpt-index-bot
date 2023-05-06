import os

import pinecone
from google.cloud import secretmanager
from langchain import OpenAI
from llama_index import GPTVectorStoreIndex, LLMPredictor, OpenAIEmbedding, ServiceContext, StorageContext
from llama_index.vector_stores import PineconeVectorStore

# 環境変数の取得

SLACK_WEBHOOK_URL_SECRET_ID = os.environ["SLACK_WEBHOOK_URL_SECRET_ID"]
PINECONE_API_KEY_SECRET_ID = os.environ["PINECONE_API_KEY_SECRET_ID"]
OPENAI_API_KEY_SECRET_ID = os.environ["OPENAI_API_KEY_SECRET_ID"]

CHANNEL_NAME = os.environ["CHANNEL_NAME"]
USERNAME = os.environ["USERNAME"]
INDEX_NAME = os.environ["INDEX_NAME"]
PINECONE_ENVIRONMENT = os.environ["PINECONE_ENVIRONMENT"]
PROJECT_ID = os.environ["PROJECT_ID"]

PREDICTOR_MODEL_NAME = "gpt-3.5-turbo"
EMBEDDING_MODEL_NAME = "text-embedding-ada-002"
SIMILARITY_TOP_K = 3
VECTOR_SIZE = 1536

# secret mangerでsecretの取得
client = secretmanager.SecretManagerServiceClient()
SLACK_WEBHOOK_URL = client.access_secret_version(
    request={"name": f"projects/{PROJECT_ID}/secrets/{SLACK_WEBHOOK_URL_SECRET_ID}/versions/latest"}
).payload.data.decode("UTF-8")
PINECONE_API_KEY = client.access_secret_version(
    request={"name": f"projects/{PROJECT_ID}/secrets/{PINECONE_API_KEY_SECRET_ID}/versions/latest"}
).payload.data.decode("UTF-8")
OPENAI_API_KEY = client.access_secret_version(
    request={"name": f"projects/{PROJECT_ID}/secrets/{OPENAI_API_KEY_SECRET_ID}/versions/latest"}
).payload.data.decode("UTF-8")

# FIXME: llama_index ver0.6.1ではEmbeddingモデルにapi_keyを指定することができないので、環境変数にOPENAI_API_KEYを設定する
os.environ["OPENAI_API_KEY"] = OPENAI_API_KEY


def setup_index():
    pinecone.init(api_key=PINECONE_API_KEY, environment=PINECONE_ENVIRONMENT)
    pinecone_index = pinecone.Index(INDEX_NAME)
    vector_store = PineconeVectorStore(pinecone_index=pinecone_index)
    storage_context = StorageContext.from_defaults(vector_store=vector_store)

    llm_predictor = LLMPredictor(
        llm=OpenAI(temperature=0, model_name=PREDICTOR_MODEL_NAME, openai_api_key=OPENAI_API_KEY)
    )
    embed_model = OpenAIEmbedding(model=EMBEDDING_MODEL_NAME)
    service_context = ServiceContext.from_defaults(llm_predictor=llm_predictor, embed_model=embed_model)

    index = GPTVectorStoreIndex.from_documents(
        documents=[], service_context=service_context, storage_context=storage_context
    )

    return index, pinecone_index
