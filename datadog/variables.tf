variable "datadog_site" {
  description = "Datadog site: datadoghq.com (US) or datadoghq.eu (EU)."
  type        = string
  default     = "datadoghq.com"
}

variable "repo_full_name" {
  description = "GitHub owner/repo under test."
  type        = string
  default     = "leandro4979-hub/refined-github"
}

variable "upstream_repo_full_name" {
  description = "Upstream refined-github repo, used to track extension release health."
  type        = string
  default     = "refined-github/refined-github"
}

variable "service_tag" {
  description = "Service tag applied to every Synthetics test, dashboard, and monitor."
  type        = string
  default     = "refined-github"
}

variable "common_tags" {
  description = "Tags applied to all Datadog resources. `e2e-tests` is required so the existing GitHub Actions workflow (test_search_query: 'tag:e2e-tests') runs these tests in CI."
  type        = list(string)
  default = [
    "e2e-tests",
    "service:refined-github",
    "repo:leandro4979-hub/refined-github",
    "env:prod",
    "managed-by:terraform",
  ]
}

variable "synthetics_locations" {
  description = "Datadog Synthetics managed locations to run tests from."
  type        = list(string)
  default     = ["aws:us-east-1", "aws:us-west-2"]
}

variable "webhook_url" {
  description = "Destination for the Datadog webhook. Recommended: the ntfy-bridge Lambda Function URL. Fallback: https://ntfy.sh/<your-topic> (shows raw JSON unless the bridge is used)."
  type        = string
  default     = ""
}

variable "webhook_custom_headers" {
  description = "Custom headers sent on every webhook POST. Used only for the direct-to-ntfy fallback."
  type        = map(string)
  default     = {}
}

variable "latency_threshold_ms" {
  description = "p95 latency threshold (milliseconds) that triggers the latency monitor."
  type        = number
  default     = 2000
}

variable "failure_ratio_threshold" {
  description = "Failed-run ratio (0.0-1.0) over the evaluation window that triggers the success-rate monitor. 0.05 == 95% success."
  type        = number
  default     = 0.05
}
