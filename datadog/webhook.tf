# ---------------------------------------------------------------------------
# Webhook integration that delivers monitor alerts to mobile push.
#
# Recommended target: the ntfy-bridge Lambda Function URL (see lambda/).
#   Datadog default JSON payload -> Lambda -> clean ntfy.sh message -> push.
#
# Fallback target: https://ntfy.sh/<your-topic> directly. In that case set
#   webhook_custom_headers = { Title = "...", Priority = "urgent", Tags = "..." }
#   and note ntfy will display the raw JSON body unless the Lambda is used.
# ---------------------------------------------------------------------------

resource "datadog_webhook" "ntfy" {
  count = var.webhook_url == "" ? 0 : 1

  name           = "refined-github-ntfy"
  url            = var.webhook_url
  custom_headers = length(var.webhook_custom_headers) > 0 ? jsonencode(var.webhook_custom_headers) : null
}
