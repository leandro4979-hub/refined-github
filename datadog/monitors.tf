# ---------------------------------------------------------------------------
# Monitors: success-rate (uptime), latency, and any-failed-run alerts.
# All notify the ntfy webhook created in webhook.tf (@webhook-refined-github-ntfy).
# Metric names to confirm in Datadog > Metrics > Explorer:
#   synthetics.test_runs   (count, tagged result:passed|failed, synthetics_test)
#   synthetics.test_latency (gauge, ms, tagged synthetics_test)
# ---------------------------------------------------------------------------

# A. Uptime — any failed Synthetics run in the last 5 minutes (per test).
resource "datadog_monitor" "uptime_failed_run" {
  name    = "[refined-github] Synthetics failed run (uptime)"
  type    = "metric alert"
  message = <<-EOT
    A refined-github Synthetics test reported a failed run in the last 5m.
    Test: {{synthetics_test.name}}

    See dashboard: https://app.datadoghq.com/dashboard/${datadog_dashboard_json.refined_github.id}
    @webhook-refined-github-ntfy
  EOT
  query   = "min(last_5m):sum:synthetics.test_runs{result:failed,service:${var.service_tag}}.as_count() by {synthetics_test} >= 1"

  monitor_thresholds {
    critical = 1
  }

  notify_no_data      = false
  require_full_window = false
  renotify_interval   = 60
  priority            = 1
  tags                = var.common_tags
}

# B. Success-rate — failed-run ratio over 15m exceeds threshold (default 5% => <95% success).
resource "datadog_monitor" "success_rate" {
  name    = "[refined-github] Synthetics success-rate below target"
  type    = "metric alert"
  message = <<-EOT
    refined-github Synthetics failed-run ratio exceeded ${var.failure_ratio_threshold} over the last 15m
    (success rate dropped below ${1 - var.failure_ratio_threshold} of the target).

    See dashboard: https://app.datadoghq.com/dashboard/${datadog_dashboard_json.refined_github.id}
    @webhook-refined-github-ntfy
  EOT
  query   = "(sum:synthetics.test_runs{result:failed,service:${var.service_tag}}.as_count() / sum:synthetics.test_runs{service:${var.service_tag}}.as_count()) > ${var.failure_ratio_threshold}"

  monitor_thresholds {
    critical = var.failure_ratio_threshold
    warning  = 0.02
  }

  notify_no_data      = false
  require_full_window = false
  renotify_interval   = 60
  priority            = 2
  tags                = var.common_tags
}

# C. Latency — p95 latency per test above threshold (default 2000 ms).
resource "datadog_monitor" "latency_p95" {
  name    = "[refined-github] Synthetics p95 latency high"
  type    = "metric alert"
  message = <<-EOT
    refined-github Synthetics p95 latency exceeded ${var.latency_threshold_ms} ms over the last 5m.
    Test: {{synthetics_test.name}}

    See dashboard: https://app.datadoghq.com/dashboard/${datadog_dashboard_json.refined_github.id}
    @webhook-refined-github-ntfy
  EOT
  query   = "p95(last_5m):synthetics.test_latency{service:${var.service_tag}} by {synthetics_test} > ${var.latency_threshold_ms}"

  monitor_thresholds {
    critical = var.latency_threshold_ms
    warning  = 1500
  }

  notify_no_data      = false
  require_full_window = false
  renotify_interval   = 60
  priority            = 2
  tags                = var.common_tags
}
