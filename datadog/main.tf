provider "datadog" {
  api_key = var.datadog_api_key
  app_key = var.datadog_app_key
  api_url = var.datadog_site == "datadoghq.eu" ? "https://api.datadoghq.eu" : "https://api.datadoghq.com"
}

# Pulled from a separate variable block so secrets are never committed.
# Set at apply time via environment or -var; see terraform.tfvars.example.
variable "datadog_api_key" {
  description = "Datadog API key (DD_API_KEY). Provide via DD_API_KEY env var or -var."
  type        = string
  sensitive   = true
  default     = null
}

variable "datadog_app_key" {
  description = "Datadog Application key (DD_APP_KEY). Provide via DD_APP_KEY env var or -var."
  type        = string
  sensitive   = true
  default     = null
}

locals {
  github_base    = "https://github.com/${var.repo_full_name}"
  github_api     = "https://api.github.com/repos/${var.repo_full_name}"
  upstream_api   = "https://api.github.com/repos/${var.upstream_repo_full_name}"
  github_headers = { Accept = "application/vnd.github+json" }
}
