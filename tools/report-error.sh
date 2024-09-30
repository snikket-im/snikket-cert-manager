#!/bin/bash

set -euo pipefail

# Nothing to do if DSN is not configured
if [[ -z "$REPORT_DSN" ]]; then
	exit 0;
fi

REPORT_DOMAIN=$(echo "${REPORT_DSN?}" | sed 's|^.*@||;s|/.*$||')
REPORT_PROJECT_ID=$(echo "${REPORT_DSN?}" | grep -o '[0-9]*$')
REPORT_KEY=$(echo "${REPORT_DSN?}" | sed 's|^.*://||;s/@.*$//')

if [[ -z "$REPORT_KEY" || -z "$REPORT_PROJECT_ID" || -z "$REPORT_DOMAIN" ]]; then
	echo "EE: Unable to parse DSN: $REPORT_DSN"
	exit 1;
fi

JSON_DATA=$(jq -n --arg type "${1?}" --rawfile value "${2?}" '{ "exception": [{ "type": $type, "value": $value }] }')

if ! curl -X POST --data "$JSON_DATA" -H 'Content-Type: application/json' -H 'Content-Type: application/json' -H "X-Sentry-Auth: Sentry sentry_version=7, sentry_key=${SENTRY_KEY}, sentry_client=report-failure-sh/0.1" "https://${REPORT_DOMAIN}/api/${REPORT_PROJECT_ID}/store/"; then
	echo "EE: Failed to post error report"
	exit 1;
fi

