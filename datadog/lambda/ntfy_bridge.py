"""
ntfy-bridge Lambda: transforms a Datadog monitor webhook (default JSON payload)
into a clean ntfy.sh push notification.

Flow:  Datadog monitor  ->  @webhook-refined-github-ntfy  ->  this Lambda
                                                              ->  ntfy.sh topic
                                                              ->  ntfy iOS app (push)

Deploy with SAM (template.yaml) or the AWS console. Configure environment vars:
  NTFY_URL   e.g. https://ntfy.sh/your-private-topic   (REQUIRED)
  NTFY_TOKEN optional, set only if your ntfy topic requires an access token

The Lambda does not log credentials. It returns 200 to Datadog so the webhook
does not retry unnecessarily; ntfy delivery failures return a non-2xx code and
a short reason so Datadog surfaces a failed webhook if you enable that.
"""
import json
import os
import urllib.request
import urllib.error

NTFY_URL = os.environ.get("NTFY_URL", "")
NTFY_TOKEN = os.environ.get("NTFY_TOKEN", "")


def _post_ntfy(message: str, title: str, priority: str, tags: str) -> tuple[int, str]:
    headers = {
        "Title": title[:250],
        "Priority": priority,
        "Tags": tags,
    }
    if NTFY_TOKEN:
        headers["Authorization"] = f"Bearer {NTFY_TOKEN}"

    req = urllib.request.Request(
        NTFY_URL,
        data=message.encode("utf-8"),
        headers=headers,
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            return resp.status, "ok"
    except urllib.error.HTTPError as exc:
        return exc.code, f"ntfy http error {exc.code}"
    except Exception as exc:  # noqa: BLE001
        return 502, f"ntfy error: {type(exc).__name__}"


def handler(event, context):  # noqa: ANN001
    if not NTFY_URL:
        return {"statusCode": 500, "body": "NTFY_URL not configured"}

    raw = event.get("body") or ""
    if isinstance(raw, bytes):
        raw = raw.decode("utf-8", errors="replace")

    try:
        data = json.loads(raw) if raw else {}
    except json.JSONDecodeError:
        data = {"title": "Datadog", "text": raw}

    title = data.get("title") or data.get("alert_title") or "Datadog Alert"
    alert_type = data.get("alert_type", "")
    transition = data.get("alert_transition", "")
    query = data.get("alert_query") or data.get("query", "")
    link = data.get("link") or data.get("link_url", "")
    priority_field = str(data.get("priority", "")).upper()

    priority = "urgent" if (priority_field in ("P1", "P2") or alert_type == "error") else "default"
    tags = "rotating_light,datadog" if alert_type == "error" else "white_check_mark,datadog"

    lines = [title]
    if alert_type or transition:
        lines.append(f"{alert_type} / {transition}".strip(" /"))
    if query:
        lines.append(query)
    if link:
        lines.append(link)
    message = "\n".join(lines)

    status, reason = _post_ntfy(message, f"Datadog: refined-github", priority, tags)
    return {"statusCode": status, "body": reason}
