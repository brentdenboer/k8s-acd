# Example using Terraform Cloud backend for state management.
# Replace with your preferred backend (e.g., S3).
terraform {
  cloud {
    organization = "brentdenboer"

    workspaces {
      name = "infra-prod-eu-1"
    }
  }
}
