import json
import logging
import os
from logging import DEBUG, StreamHandler, getLogger

from flask import Request
from google.cloud import pubsub_v1
from slack_bolt import App
from slack_bolt.adapter.google_cloud_functions import SlackRequestHandler

# ロガーの準備
logger = getLogger(__name__)
logger.setLevel(DEBUG)
ch = StreamHandler()
ch.setLevel(DEBUG)
formatter = logging.Formatter("%(asctime)s - %(message)s")
ch.setFormatter(formatter)
logger.addHandler(ch)


slack_token = os.environ.get("SLACK_BOT_TOKEN")
slack_singing_secret = os.environ.get("SLACK_SINGING_SECRET")
app = App(token=slack_token, signing_secret=slack_singing_secret, process_before_response=True)
handler = SlackRequestHandler(app)

project_id = os.environ.get("PROJECT_ID")
topic_id = os.environ.get("TOPIC_ID")
publisher = pubsub_v1.PublisherClient()
topic_path = publisher.topic_path(project_id, topic_id)


@app.command("/search-index")
def search_index(ack, respond, command):
    ack()
    data = {"type": "search", "query": command["text"]}
    data_str = json.dumps(data).encode("utf-8")
    _ = publisher.publish(topic_path, data_str)
    respond(f"質問を受け付けました、回答まで少々お待ちください\n\nメッセージ: {command['text']}")


@app.command("/register-index")
def register_index(ack, respond, command):
    ack()
    data = {"type": "register", "query": command["text"]}
    data_str = json.dumps(data).encode("utf-8")
    _ = publisher.publish(topic_path, data_str)
    respond(f"登録を受け付けました、完了まで少々お待ちください\n\nメッセージ: {command['text']}")


# Cloud Functions で呼び出されるエントリポイント
def slack_bot(request: Request):
    """slack のイベントリクエストを受信して各処理を実行する関数

    Args:
        request: Slack のイベントリクエスト

    Returns:
        SlackRequestHandler への接続
    """
    try:
        header = request.headers
        if header.get("Content-Type") == "application/json":
            body = request.get_json()
        else:
            body = {}

        # URL確認を通すとき
        if body.get("type") == "url_verification":
            logger.info("url verification started")
            headers = {"Content-Type": "application/json"}
            res = json.dumps({"challenge": body["challenge"]})
            logger.debug(f"res: {res}")
            return (res, 200, headers)
        # 応答が遅いと Slack からリトライを何度も受信してしまうため、リトライ時は処理しない
        elif header.get("x-slack-retry-num"):
            logger.info("slack retry received")
            return {"statusCode": 200, "body": json.dumps({"message": "No need to resend"})}

        # handler への接続 class: flask.wrappers.Response
        return handler.handle(request)
    except Exception as e:
        logger.exception(f"Unknown Error: {e}")
