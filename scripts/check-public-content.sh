#!/usr/bin/env bash

set -euo pipefail

SCAN_ROOT="${1:-bloghome/public}"

if [[ ! -d "${SCAN_ROOT}" ]]; then
  echo "Public output not found: ${SCAN_ROOT}" >&2
  exit 2
fi

declare -a PATTERNS=(
  'mailto:'
  'linkedin\.com/in/'
  'docs\.google\.com/(document|spreadsheets|presentation)/d/'
  '\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b'
  '\b10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\b'
  '\b192\.168\.[0-9]{1,3}\.[0-9]{1,3}\b'
  '\b172\.(1[6-9]|2[0-9]|3[01])\.[0-9]{1,3}\.[0-9]{1,3}\b'
  'physical location'
  'hosted by:'
  'undergrad:'
)

FAILED=0

for PATTERN in "${PATTERNS[@]}"; do
  if MATCHED_FILES="$(rg --ignore-case --files-with-matches --glob '*.html' --glob '*.xml' "${PATTERN}" "${SCAN_ROOT}")"; then
    echo "Privacy check found a prohibited public-data pattern in:"
    while IFS= read -r MATCHED_FILE; do
      echo "  - ${MATCHED_FILE}"
    done <<< "${MATCHED_FILES}"
    FAILED=1
  fi
done

if [[ "${FAILED}" -ne 0 ]]; then
  echo "Privacy check failed: review the matches above." >&2
  exit 1
fi

echo "Privacy check passed."
