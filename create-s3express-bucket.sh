#!/bin/bash

# Simple S3Express Bucket Creation Script

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Check if bucket name is provided
if [ $# -eq 0 ]; then
    echo -e "${RED}Usage: $0 <bucket-name> [region]${NC}"
    echo "Example: $0 my-s3express-bucket us-east-1"
    exit 1
fi

BUCKET_NAME=$1
REGION=${2:-us-east-1}

echo "Creating S3Express bucket: $BUCKET_NAME in region: $REGION"

# Create S3Express bucket
aws s3api create-bucket \
    --bucket "$BUCKET_NAME" \
    --region "$REGION" \
    --create-bucket-configuration LocationConstraint="$REGION" \
    --s3express-configuration '{"DataRedundancy":"SingleAvailabilityZone","Type":"Directory"}'

echo -e "${GREEN}✅ S3Express bucket '$BUCKET_NAME' created successfully!${NC}"
echo "URL: https://$BUCKET_NAME.s3express-$REGION.amazonaws.com"
