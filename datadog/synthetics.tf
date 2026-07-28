# ---------------------------------------------------------------------------
# Datadog Synthetics API tests for the refined-github repo / CI surfaces.
# All tests carry the `e2e-tests` tag so the existing GitHub Actions workflow
# (.github/workflows/datadog-synthetics.yml, test_search_query: 'tag:e2e-tests')
# runs them on every push and pull request to main.
# ---------------------------------------------------------------------------

# 1. Repository page availability + latency.
resource "datadog_synthetics_test" "repo_page" {
  type    = "api"
  subtype = "http"
  status  = "live"
  name    = "refined-github · repo page availability"
  message = "The refined-github repository page did not return 200 or exceeded the latency budget. Check https://github.com/${var.repo_full_name} and GitHub status."

  request_definition {
    method = "GET"
    url    = local.github_base
  }

  assertion {
    type     = "statusCode"
    operator = "is"
    target   = "200"
  }

  assertion {
    type     = "responseTime"
    operator = "lessThan"
    target   = 2000
  }

  locations = var.synthetics_locations

  options_list {
    tick_every           = 300 # every 5 minutes
    min_failure_duration = 60
    min_location_failed  = 1
    follow_redirects     = true
    retry {
      count    = 1
      interval = 300
    }
  }

  tags = var.common_tags
}

# 2. CI/CD pipeline health via the GitHub Actions runs API.
#    Unauthenticated GitHub API calls are rate-limited to 60 req/h; at a
#    10-minute tick this is well within budget. If you raise frequency, add a
#    GITHUB_TOKEN header via request_headers (see README).
resource "datadog_synthetics_test" "ci_runs" {
  type    = "api"
  subtype = "http"
  status  = "live"
  name    = "refined-github · GitHub Actions runs API"
  message = "The GitHub Actions runs API for refined-github is not responding 200. CI may be degraded or GitHub API is rate-limiting."

  request_headers = local.github_headers

  request_definition {
    method = "GET"
    url    = "${local.github_api}/actions/runs?per_page=1"
  }

  assertion {
    type     = "statusCode"
    operator = "is"
    target   = "200"
  }

  assertion {
    type     = "responseTime"
    operator = "lessThan"
    target   = 2500
  }

  locations = var.synthetics_locations

  options_list {
    tick_every           = 600 # every 10 minutes
    min_failure_duration = 120
    min_location_failed  = 1
    follow_redirects     = true
    retry {
      count    = 1
      interval = 300
    }
  }

  tags = var.common_tags
}

# 3. Extension release health via the upstream refined-github latest release.
#    Monitors the upstream (which actually publishes releases) so the metric
#    reflects real extension release availability rather than the fork's 404.
resource "datadog_synthetics_test" "upstream_release" {
  type    = "api"
  subtype = "http"
  status  = "live"
  name    = "refined-github · upstream latest release API"
  message = "The upstream refined-github releases/latest endpoint did not return 200. Extension release feed may be unavailable."

  request_headers = local.github_headers

  request_definition {
    method = "GET"
    url    = "${local.upstream_api}/releases/latest"
  }

  assertion {
    type     = "statusCode"
    operator = "is"
    target   = "200"
  }

  assertion {
    type     = "responseTime"
    operator = "lessThan"
    target   = 2500
  }

  locations = var.synthetics_locations

  options_list {
    tick_every           = 900 # every 15 minutes
    min_failure_duration = 180
    min_location_failed  = 1
    follow_redirects     = true
    retry {
      count    = 1
      interval = 300
    }
  }

  tags = var.common_tags
}
