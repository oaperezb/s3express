#!/bin/bash
set -euo pipefail

# Clean up AWS credentials (remove any newlines)
export AWS_ACCESS_KEY_ID=$(echo $AWS_ACCESS_KEY_ID | tr -d '\n\r')
export AWS_SECRET_ACCESS_KEY=$(echo $AWS_SECRET_ACCESS_KEY | tr -d '\n\r')

# Test AWS credentials and bucket access
echo "Testing AWS credentials..."
aws sts get-caller-identity

echo "Testing S3Express bucket access..."
aws s3 ls s3://$S3EXPRESS_BUCKET_NAME --region $AWS_REGION

echo "Mounting S3Express bucket..."
# Mount S3Express bucket with increased timeout
timeout 60 mount-s3 --region $AWS_REGION $S3EXPRESS_BUCKET_NAME /mnt/s3express &

# Wait for mount to be ready
echo "Waiting for mount to be ready..."
sleep 10

# Check if mount is successful
if mount | grep -q "/mnt/s3express"; then
    echo "S3Express bucket mounted successfully!"
    ls -la /mnt/s3express
else
    echo "Mount failed or not ready yet"
    ps aux | grep mount-s3 || echo "mount-s3 process not found"
fi

# Keep container running
tail -f /dev/null
