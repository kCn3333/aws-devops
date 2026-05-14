#!/usr/bin/env bash
# bootstrap-backend.sh
# Creates S3 bucket and DynamoDB table for Terraform remote state.
# Run ONCE per AWS account. Idempotent — safe to re-run.

set -euo pipefail

BUCKET_NAME="${1:-kcn-terraform-state}"
TABLE_NAME="terraform-state-lock"
REGION="eu-north-1"

echo "==> Creating S3 state bucket: ${BUCKET_NAME}"
aws s3api create-bucket \
  --bucket "${BUCKET_NAME}" \
  --region "${REGION}" \
  --create-bucket-configuration LocationConstraint="${REGION}"

echo "==> Enabling versioning"
aws s3api put-bucket-versioning \
  --bucket "${BUCKET_NAME}" \
  --versioning-configuration Status=Enabled

echo "==> Blocking public access"
aws s3api put-public-access-block \
  --bucket "${BUCKET_NAME}" \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

echo "==> Enabling AES256 encryption"
aws s3api put-bucket-encryption \
  --bucket "${BUCKET_NAME}" \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}
    }]
  }'

echo "==> Creating DynamoDB lock table: ${TABLE_NAME}"
aws dynamodb create-table \
  --table-name "${TABLE_NAME}" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "${REGION}"

echo "==> Done! Backend resources created successfully."
echo "    Bucket : ${BUCKET_NAME}"
echo "    Table  : ${TABLE_NAME}"
echo "    Region : ${REGION}"
