from .prompt import CUSTOM_REFINE_PROMPT, CUSTOM_TEXT_QA_PROMPT
from .setup import setup_index, SIMILARITY_TOP_K


def search_index(search_query: str) -> str:
    index, _ = setup_index()

    response = index.query(
        search_query,
        similarity_top_k=SIMILARITY_TOP_K,
        text_qa_template=CUSTOM_TEXT_QA_PROMPT,
        refine_template=CUSTOM_REFINE_PROMPT,
    )

    response_message = format_search_result(response)

    return response_message


def format_search_result(response) -> str:
    response_message = f"{response.response}\n\n"

    reffer_urls = set([source_node.extra_info["url"] for source_node in response.source_nodes])
    for i, url in enumerate(reffer_urls):
        response_message += f"\n参考url{i+1}: {url}"
    return response_message
