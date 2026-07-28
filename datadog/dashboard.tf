resource "datadog_dashboard_json" "refined_github" {
  dashboard = <<EOT
{
  "title": "Refined GitHub - Synthetics",
  "description": "Live status, latency, and success-rate for refined-github Synthetics checks. Managed by Terraform.",
  "layout_type": "ordered",
  "is_read_only": false,
  "tags": ["service:refined-github", "repo:leandro4979-hub/refined-github", "managed-by:terraform"],
  "template_variables": [
    { "name": "synthetics_test", "prefix": "synthetics_test", "default": "*" }
  ],
  "widgets": [
    {
      "id": 1,
      "definition": {
        "type": "query_value",
        "title": "Overall success rate (1h)",
        "requests": [
          { "q": "(sum:synthetics.test_runs{result:passed,service:${var.service_tag}}.as_count() / sum:synthetics.test_runs{service:${var.service_tag}}.as_count()) * 100", "aggregator": "last" }
        ],
        "autoscale": true,
        "precision": 2
      }
    },
    {
      "id": 2,
      "definition": {
        "type": "timeseries",
        "title": "Latency p95 by test (ms)",
        "requests": [
          { "q": "p95:synthetics.test_latency{service:${var.service_tag}} by {synthetics_test}", "display_type": "line", "style": { "palette": "warm" } }
        ],
        "yaxis": { "label": "ms", "include_zero": true }
      }
    },
    {
      "id": 3,
      "definition": {
        "type": "timeseries",
        "title": "Success rate over time (%)",
        "requests": [
          { "q": "(sum:synthetics.test_runs{result:passed,service:${var.service_tag}}.as_count() / sum:synthetics.test_runs{service:${var.service_tag}}.as_count()) * 100", "display_type": "line", "style": { "palette": "green_to_orange" } }
        ],
        "yaxis": { "label": "%", "min": "0", "max": "100" }
      }
    },
    {
      "id": 4,
      "definition": {
        "type": "timeseries",
        "title": "Test runs by result",
        "requests": [
          { "q": "sum:synthetics.test_runs{result:passed,service:${var.service_tag}}.as_count()", "display_type": "bars", "style": { "palette": "green_to_orange" } },
          { "q": "sum:synthetics.test_runs{result:failed,service:${var.service_tag}}.as_count()", "display_type": "bars", "style": { "palette": "classic" } }
        ]
      }
    },
    {
      "id": 5,
      "definition": {
        "type": "toplist",
        "title": "Failed runs by test (1h)",
        "requests": [
          { "q": "top(sum:synthetics.test_runs{result:failed,service:${var.service_tag}}.as_count() by {synthetics_test}, 10, 'sum', 'desc')" }
        ]
      }
    },
    {
      "id": 6,
      "definition": {
        "type": "timeseries",
        "title": "Latency p95 by test (detailed, ms)",
        "requests": [
          { "q": "p95:synthetics.test_latency{service:${var.service_tag}} by {synthetics_test}", "display_type": "area", "style": { "palette": "cool" } }
        ],
        "yaxis": { "label": "ms", "include_zero": true }
      }
    }
  ]
}
EOT
}
