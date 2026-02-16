#!/bin/bash
# Fetch issue data from GitHub Project #3 (Gastrobrain)
#
# Usage:
#   ./scripts/gh-project-issue.sh <issue-number>          # all fields
#   ./scripts/gh-project-issue.sh <issue-number> estimate  # single field
#   ./scripts/gh-project-issue.sh <issue-number> status priority estimate  # multiple fields
#
# Available fields: title, status, priority, size, estimate, milestone, start date, end date, labels

OWNER="alemdisso"
PROJECT_NUMBER=3
ISSUE_NUMBER="$1"

if [ -z "$ISSUE_NUMBER" ]; then
  echo "Usage: $0 <issue-number> [field ...]"
  echo "Example: $0 271 estimate"
  exit 1
fi

# Fetch all project items and find the matching issue
ITEM=$(gh project item-list "$PROJECT_NUMBER" --owner "$OWNER" --format json --limit 500 \
  | jq --arg num "$ISSUE_NUMBER" '.items[] | select(.content.number == ($num | tonumber))')

if [ -z "$ITEM" ]; then
  echo "Issue #$ISSUE_NUMBER not found in project board"
  exit 1
fi

shift # remove issue number from args

if [ $# -eq 0 ]; then
  # No fields specified — show all relevant fields
  echo "$ITEM" | jq '{title, status, priority, size, estimate, milestone, "start date": ."start date", "end date": ."end date"}'
else
  # Show requested fields
  for field in "$@"; do
    value=$(echo "$ITEM" | jq -r --arg f "$field" '.[$f] // "not set"')
    echo "$field: $value"
  done
fi
