from llama_index.prompts.prompts import QuestionAnswerPrompt, RefinePrompt

CUSTOM_TEXT_QA_PROMPT_TMPL = (
    "コンテキストは以下です. \n"
    "---------------------\n"
    "{context_str}"
    "\n---------------------\n"
    "コンテキストが与えられた場合, "
    "質問に回答してください: {query_str}\n"
)
CUSTOM_TEXT_QA_PROMPT = QuestionAnswerPrompt(CUSTOM_TEXT_QA_PROMPT_TMPL)

CUSTOM_REFINE_PROMPT_TMPL = (
    "元の質問: {query_str}\n"
    "オリジナルの回答: {existing_answer}\n"
    "以下のコンテキストを使って、オリジナルの回答を推敲することができます.\n"
    "------------\n"
    "{context_msg}\n"
    "------------\n"
    "コンテキストを元に、オリジナルの回答を、より元の質問に沿ったものに推敲してください. "
    "もしコンテキストが有用なものでなければ、オリジナルの回答を返却してください"
)
CUSTOM_REFINE_PROMPT = RefinePrompt(CUSTOM_REFINE_PROMPT_TMPL)
