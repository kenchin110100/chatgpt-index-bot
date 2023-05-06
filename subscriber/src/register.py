import re
from typing import List

from llama_index import SimpleWebPageReader

from .setup import SIMILARITY_TOP_K, VECTOR_SIZE, setup_index


def register_index(register_query: str) -> str:
    index, pinecone_index = setup_index()

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
