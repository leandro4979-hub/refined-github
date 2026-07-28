#!/usr/bin/env bash
# Set the Datadog API + Application keys as GitHub repo secrets so the existing
# .github/workflows/datadog-synthetics.yml workflow can run Synthetic tests in CI.
#
# Requires: gh CLI authenticated with repo:admin scope.
# Usage:
#   DD_API_KEY=... DD_APP_KEY=... REPO=leandro4979-hub/refined-github ./set-datadog-secrets.sh
set -euo pipefail

REPO="${REPO:-leandro4979-hub/refined-github}"

: "${DD_API_KEY:?DD_API_KEY is required}"
: "${DD_APP_KEY:?DD_APP_KEY is required}"

echo "Setting DD_API_KEY and DD_APP_KEY on ${REPO}..."
gh secret set DD_API_KEY --repo "${REPO}" --body "${DD_API_KEY}"
gh secret set DD_APP_KEY --repo "${REPO}" --body "${DD_APP_KEY}"

echo "Verifying..."
gh secret list --repo "${REPO}"
echo "Done. The datadog-synthetics.yml workflow can now run tag:e2e-tests Synthetic tests on push/PR to main."
