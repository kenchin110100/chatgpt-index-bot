import os
import re
from typing import List

import pinecone
from llama_index import SimpleWebPageReader

from .setup import setup_index

INDEX_NAME = os.environ["INDEX_NAME"]
PINECONE_API_KEY = os.environ["PINECONE_API_KEY"]
PINECONE_ENVIRONMENT = os.environ["PINECONE_ENVIRONMENT"]

PREDICTOR_MODEL_NAME = "gpt-3.5-turbo"
EMBEDDING_MODEL_NAME = "text-embedding-ada-002"
SIMILARITY_TOP_K = 3
VECTOR_SIZE = 1536


def register_index(register_query: str) -> str:
    pinecone_index = pinecone.Index(INDEX_NAME)
    index = setup_index(
        predictor_model_name=PREDICTOR_MODEL_NAME, embedding_model_name=EMBEDDING_MODEL_NAME, db_index=pinecone_index
    )

    urls = find_urls(register_query)

    if len(urls) == 0:
        return f"入力された文書には、URLが含まれていませんでした: {register_query}"

    response_message = ""
    target_urls = []
    for url in urls:
        query_response = pinecone_index.query(
            top_k=SIMILARITY_TOP_K,
            include_metadata=True,
            # dummyのベクトル
            vector=[0.1] * VECTOR_SIZE,
            filter={"extra_info_url": {"$in": [url]}},
        )
        if len(query_response["matches"]) > 0:
            response_message += f"{url} は既に登録済みでした\n"
        else:
            target_urls.append(url)

    if len(target_urls) == 0:
        return response_message

    documents = SimpleWebPageReader(html_to_text=True).load_data(target_urls)
    # extra_infoにurlを追加しつつ、DBに登録
    for document, url in zip(documents, target_urls):
        document.extra_info = {"url": url}
        index.insert(document)
        response_message += f"{url} の新規登録を行いました\n"

    return response_message


def find_urls(register_query: str) -> List[str]:
    pattern = "https?://[\w/:%#\$&\?\(\)~\.=\+\-]+"
    url_list = re.findall(pattern, register_query)
    return url_list
