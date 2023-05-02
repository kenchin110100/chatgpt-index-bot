from llama_index import LLMPredictor, ServiceContext, GPTPineconeIndex, OpenAIEmbedding
from langchain import OpenAI


def setup_index(predictor_model_name: str, embedding_model_name: str, db_index) -> GPTPineconeIndex:
    llm_predictor = LLMPredictor(llm=OpenAI(temperature=0, model_name=predictor_model_name))

    embed_model = OpenAIEmbedding(model=embedding_model_name)

    service_context = ServiceContext.from_defaults(llm_predictor=llm_predictor, embed_model=embed_model)

    index = GPTPineconeIndex.from_documents(pinecone_index=db_index, documents=[], service_context=service_context)

    return index
