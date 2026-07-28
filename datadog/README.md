# Refined GitHub — Datadog Synthetics Dashboard (dashboard-as-code)

Production-grade Synthetics monitoring for the `leandro4979-hub/refined-github`
repository and its CI/CD pipeline. Managed entirely with Terraform so the
dashboard, tests, monitors, and webhook are version-controlled and reproducible.

## What this creates

| Resource | Purpose |
| --- | --- |
| `datadog_synthetics_test.repo_page` | API test — repo page availability + <2s latency (`github.com/leandro4979-hub/refined-github`) |
| `datadog_synthetics_test.ci_runs` | API test — GitHub Actions runs API health (CI pipeline reliability) |
| `datadog_synthetics_test.upstream_release` | API test — upstream refined-github latest release feed (extension release availability) |
| `datadog_dashboard_json.refined_github` | Dashboard — success rate, p95 latency, runs-by-result, failed-runs toplist |
| `datadog_monitor.uptime_failed_run` | Alert — any failed Synthetic run within 5m (uptime) |
| `datadog_monitor.success_rate` | Alert — failed-run ratio > 5% over 15m (success rate < 95%) |
| `datadog_monitor.latency_p95` | Alert — p95 latency > 2000 ms per test |
| `datadog_webhook.ntfy` | Webhook integration → ntfy-bridge Lambda → mobile push |

All tests carry the `e2e-tests` tag, so the existing
[`.github/workflows/datadog-synthetics.yml`](../.github/workflows/datadog-synthetics.yml)
workflow (`test_search_query: 'tag:e2e-tests'`) runs them on every push and
pull request to `main`.

## Prerequisites

1. **Datadog API + Application keys** with Synthetics, Monitors, and Dashboards
   permissions. Create them at
   [Organization Settings → API Keys](https://app.datadoghq.com/organization-settings/api-keys)
   and
   [Application Keys](https://app.datadoghq.com/organization-settings/application-keys).
2. **Terraform** ≥ 1.4.
3. **AWS SAM CLI** (only if you deploy the ntfy-bridge Lambda for mobile push).
4. **GitHub `gh` CLI** with `repo:admin` to set CI secrets.

## 1. Deploy the mobile-push bridge (ntfy)

The alerting path is: `Datadog monitor → @webhook-refined-github-ntfy → ntfy-bridge Lambda → ntfy.sh → ntfy iOS app`.

1. Install the free **ntfy** app on your iPhone and pick a private topic, e.g.
   `https://ntfy.sh/<random-hard-to-guess-topic>`.
2. Deploy the transformer Lambda:

   ```bash
   cd datadog/lambda
   sam build && sam deploy --guided \
     --parameter-overrides NtfyUrl="https://ntfy.sh/<your-topic>" NtfyToken=""
   ```

   The SAM output prints a **Function URL** — copy it.

3. (Fallback, no Lambda) Point the webhook directly at ntfy. Alerts arrive as a
   raw JSON body and you set headers via `webhook_custom_headers`. Less readable
   but zero deploy.

## 2. Apply the Terraform

```bash
cd datadog
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars: set webhook_url to the Lambda Function URL from step 1

export DD_API_KEY=...   # never commit these
export DD_APP_KEY=...

terraform init
terraform plan -var-file=terraform.tfvars      # verify: tests, dashboard, monitors, webhook
terraform apply -var-file=terraform.tfvars
```

The apply prints the dashboard URL:
`https://app.datadoghq.com/dashboard/<dashboard_id>`.

## 3. Enable the CI workflow

The merged `datadog-synthetics.yml` runs `tag:e2e-tests` tests on push/PR to
`main`, but it needs the Datadog keys as repo secrets:

```bash
DD_API_KEY=... DD_APP_KEY=... ./scripts/set-datadog-secrets.sh
```

## Verification

After apply, confirm in Datadog:

- **Synthetics → Tests**: three tests tagged `e2e-tests`, status `Live`.
- **Dashboards → Refined GitHub - Synthetics**: success rate, latency, runs.
- **Monitors**: three monitors, each notifying `@webhook-refined-github-ntfy`.
- **Integrations → Webhooks**: `refined-github-ntfy` pointing at the Lambda URL.
- Trigger a test alert (e.g. temporarily lower `failure_ratio_threshold` and run
  `terraform apply`) and confirm a push arrives on your phone.

> Confirm metric names in **Metrics → Explorer** if a widget/monitor shows no
> data: `synthetics.test_runs` and `synthetics.test_latency`. Tag filters use
> `service:refined-github` and `result:passed|failed`.

## Rollback

```bash
cd datadog
terraform destroy -var-file=terraform.tfvars       # removes tests, dashboard, monitors, webhook
```

To disable CI-side runs without destroying: remove the `e2e-tests` tag from
`common_tags` in `variables.tf` and re-apply, or delete the
`DD_API_KEY`/`DD_APP_KEY` repo secrets:

```bash
gh secret delete DD_API_KEY  --repo leandro4979-hub/refined-github
gh secret delete DD_APP_KEY  --repo leandro4979-hub/refined-github
```

To remove the Lambda: `sam delete` in `datadog/lambda`.

## Notes & limitations

- **Browser test (optional):** Datadog browser tests cannot validate *your
  installed* Refined GitHub extension — they only check the GitHub page surface.
  Add one via the Datadog UI if you want page-render checks beyond the API tests.
- **GitHub API rate limits:** the CI-runs test is unauthenticated (60 req/h).
  At a 10-minute tick this is safe. To raise frequency, add a `GITHUB_TOKEN`
  header to the test request in `synthetics.tf`.
- **EU sites:** set `datadog_site = "datadoghq.eu"` and use the EU API host.
