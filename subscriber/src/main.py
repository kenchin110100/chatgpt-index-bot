import base64
import json
import logging
import os
from logging import DEBUG, StreamHandler, getLogger

import urllib3
from flask import Flask, request

from .register import register_index
from .search import search_index
from .setup import CHANNEL_NAME, SLACK_WEBHOOK_URL, USERNAME

# ロガーの準備
logger = getLogger(__name__)
logger.setLevel(DEBUG)
ch = StreamHandler()
ch.setLevel(DEBUG)
formatter = logging.Formatter("%(asctime)s - %(message)s")
ch.setFormatter(formatter)
logger.addHandler(ch)

app = Flask(__name__)
http = urllib3.PoolManager()


@app.route("/", methods=["POST"])
def index():
    try:
        MESSAGE_FORMAT = {"channel": CHANNEL_NAME, "username": USERNAME}
        data = request.get_json()
        if not data:
            msg = "no Pub/Sub message received"
            logger.error(f"error: {msg}")
            return f"Bad Request: {msg}", 400

        if not isinstance(data, dict) or "message" not in data:
            msg = "invalid Pub/Sub message format"
            logger.error(f"error: {msg}")
            return f"Bad Request: {msg}", 400

        pubsub_message = data["message"]

        if isinstance(pubsub_message, dict) and "data" in pubsub_message:
            data = base64.b64decode(pubsub_message["data"]).decode("utf-8").strip()
            data = json.loads(data)

        logger.info(data)
        type_ = data["type"]
        query = data["query"]
        if type_ == "search":
            response_message = search_index(query)
        elif type_ == "register":
            response_message = register_index(query)
        else:
            response_message = f"想定外のコマンドです: {type_}"

        MESSAGE_FORMAT["text"] = response_message
        encoded_msg = json.dumps(MESSAGE_FORMAT).encode("utf-8")
        resp = http.request("POST", SLACK_WEBHOOK_URL, body=encoded_msg)

        return (resp, 200)

    except Exception as e:
        msg = "internal error"
        logger.info(f"error: {e}", exc_info=True)

        response_message = f"エラーが発生しました\n{e}"

        MESSAGE_FORMAT["text"] = response_message
        encoded_msg = json.dumps(MESSAGE_FORMAT).encode("utf-8")
        resp = http.request("POST", SLACK_WEBHOOK_URL, body=encoded_msg)

        return "Internal Error", 500


if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))
