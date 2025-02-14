#!/bin/bash

# Input: Account ID to search for
TARGET_ACCOUNT_ID=$1
if [ -z "$TARGET_ACCOUNT_ID" ]; then
  echo "Usage: $0 <sso_account_id>"
  exit 1
fi

# Parse ~/.aws/config for the matching profile
PROFILE=$(awk -v account_id="$TARGET_ACCOUNT_ID" '
  /^\[profile/ { profile = $2; gsub(/[\[\]]/, "", profile) }
  $0 ~ "sso_account_id" && $0 ~ account_id { print profile }
' ~/.aws/config)

if [ -z "$PROFILE" ]; then
  echo "ERROR: No profile found for sso_account_id: $TARGET_ACCOUNT_ID"
  exit 1
fi

echo "$PROFILE"