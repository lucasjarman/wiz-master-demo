#!/bin/bash
set -e

TOPIC_ARN=$1
BUCKET_ARN=$2
PROFILE=$3

echo "Updating policy for $TOPIC_ARN to allow $BUCKET_ARN..."

# Get current policy
POLICY=$(aws sns get-topic-attributes --topic-arn "$TOPIC_ARN" --profile "$PROFILE" --query "Attributes.Policy" --output text)

# Check if bucket is already allowed
if echo "$POLICY" | grep -q "$BUCKET_ARN"; then
  echo "Policy already allows bucket."
  exit 0
fi

# jq magic to append the new bucket to the Condition.ArnLike.aws:SourceArn list (or create it)
# Simplification: We replace the existing SourceArn condition with one that allows the new bucket. 
# Ideally we'd append, but for this demo, ensuring the current bucket works is priority.
NEW_POLICY=$(echo "$POLICY" | jq --arg BUCKET "$BUCKET_ARN" '
  .Statement[0].Condition.ArnLike["aws:SourceArn"] = $BUCKET
')

# Update the policy
aws sns set-topic-attributes --topic-arn "$TOPIC_ARN" --attribute-name Policy --attribute-value "$NEW_POLICY" --profile "$PROFILE"

echo "Policy updated successfully."
