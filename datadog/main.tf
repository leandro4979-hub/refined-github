provider "datadog" {
  # DD_API_KEY and DD_APP_KEY are read from the environment (standard pattern).
  #   export DD_API_KEY=...
  #   export DD_APP_KEY=...
  api_url = var.datadog_site == "datadoghq.eu" ? "https://api.datadoghq.eu" : "https://api.datadoghq.com"
}

locals {
  github_base    = "https://github.com/${var.repo_full_name}"
  github_api     = "https://api.github.com/repos/${var.repo_full_name}"
  upstream_api   = "https://api.github.com/repos/${var.upstream_repo_full_name}"
  github_headers = { Accept = "application/vnd.github+json" }
}
