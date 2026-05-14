# Terraform Remote State Backend

These resources are provisioned manually (bootstrap) and are not managed by Terraform.
They exist to support Terraform's own state management.

## Resources

| Resource       | Name                        | Purpose                        |
|----------------|-----------------------------|--------------------------------|
| S3 Bucket      | kcn-terraform-state         | Stores terraform state files   |
| S3 Versioning  | Enabled                     | Enables state rollback         |
| S3 Encryption  | AES256                      | Encrypts state at rest         |
| DynamoDB Table | terraform-state-lock        | Prevents concurrent applies    |

## Why Manual?

Terraform cannot manage the backend that stores its own state.
This is a one-time bootstrap per AWS account.

## Re-creating (if needed)

See: `scripts/bootstrap-backend.sh`
