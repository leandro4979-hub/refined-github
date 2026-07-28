# ---------------------------------------------------------------------------
# Browser test: loads the refined-github repository page in a real browser and
# verifies the navigation landed on the correct repo URL.
#
# Note: Datadog browser tests run in Datadog-managed browsers without your
# installed Refined GitHub extension, so this validates the GitHub page surface
# (the extension's target), not extension injection itself.
# ---------------------------------------------------------------------------

resource "datadog_synthetics_test" "repo_page_browser" {
  type       = "browser"
  status     = "live"
  name       = "refined-github · repo page browser"
  message    = "The refined-github repository page did not load or did not land on the expected URL. Check https://github.com/${var.repo_full_name} and GitHub status."
  device_ids = ["laptop_large"]
  locations  = var.synthetics_locations
  tags       = var.common_tags

  request_definition {
    method = "GET"
    url    = local.github_base
  }

  # Verify the browser landed on the refined-github repository URL.
  browser_step {
    name = "Assert current URL contains repo name"
    type = "assertCurrentUrl"
    params {
      check = "contains"
      value = "refined-github"
    }
  }

  # Verify the page actually rendered repo content (title element).
  browser_step {
    name = "Assert page contains refined-github"
    type = "assertElementContent"
    params {
      check = "contains"
      value = "refined-github"
      element = jsonencode({
        userLocator = {
          failTestOnCannotLocate = true
          values = [{
            type  = "css"
            value = "a[href='/leandro4979-hub/refined-github']"
          }]
        }
      })
    }
  }

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
}
