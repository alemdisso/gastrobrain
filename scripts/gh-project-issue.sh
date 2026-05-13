#!/bin/bash
# Fetch issue data from GitHub Project #3 (Gastrobrain)
#
# Usage:
#   ./scripts/gh-project-issue.sh <issue-number>          # all fields
#   ./scripts/gh-project-issue.sh <issue-number> estimate  # single field
#   ./scripts/gh-project-issue.sh <issue-number> status priority estimate  # multiple fields
#
# Available fields: title, status, priority, size, estimate, milestone, start date, end date

OWNER="alemdisso"
REPO="gastrobrain"
ISSUE_NUMBER="$1"

if [ -z "$ISSUE_NUMBER" ]; then
  echo "Usage: $0 <issue-number> [field ...]"
  echo "Example: $0 271 estimate"
  exit 1
fi

# Fetch project item fields directly from the issue — no full-project pagination
QUERY=$(cat <<GRAPHQL
{
  repository(owner: "$OWNER", name: "$REPO") {
    issue(number: $ISSUE_NUMBER) {
      projectItems(first: 5) {
        nodes {
          fieldValues(first: 15) {
            nodes {
              ... on ProjectV2ItemFieldTextValue {
                field { ... on ProjectV2Field { name } }
                text
              }
              ... on ProjectV2ItemFieldNumberValue {
                field { ... on ProjectV2Field { name } }
                number
              }
              ... on ProjectV2ItemFieldSingleSelectValue {
                field { ... on ProjectV2SingleSelectField { name } }
                name
              }
              ... on ProjectV2ItemFieldDateValue {
                field { ... on ProjectV2Field { name } }
                date
              }
              ... on ProjectV2ItemFieldIterationValue {
                field { ... on ProjectV2IterationField { name } }
                title
              }
            }
          }
        }
      }
    }
  }
}
GRAPHQL
)

RAW=$(gh api graphql -f query="$QUERY" 2>&1)

if echo "$RAW" | grep -q '"errors"'; then
  echo "GraphQL error: $RAW"
  exit 1
fi

NODES=$(echo "$RAW" | jq '.data.repository.issue.projectItems.nodes[0].fieldValues.nodes')

if [ "$NODES" = "null" ] || [ -z "$NODES" ]; then
  echo "Issue #$ISSUE_NUMBER not found in any project board"
  exit 1
fi

# Normalise into a flat key→value object, lowercasing field names
ITEM=$(echo "$NODES" | jq '
  [ .[]
    | select(.field != null)
    | {
        key: (.field.name | ascii_downcase),
        value: (.text // .number // .name // .date // .title // "")
      }
  ] | from_entries
')

shift # remove issue number from args

if [ $# -eq 0 ]; then
  echo "$ITEM" | jq '{title, status, priority, size, estimate, milestone, "start date", "end date"}'
else
  for field in "$@"; do
    value=$(echo "$ITEM" | jq -r --arg f "$field" '.[$f] // "not set"')
    echo "$field: $value"
  done
fi
