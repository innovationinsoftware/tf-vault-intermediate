terraform {
  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.50.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# Configure TFE provider for HCP Terraform
provider "tfe" {
  hostname = "app.terraform.io"
  token    = var.tfe_token
}

# Generate unique environment identifier
resource "random_string" "environment_id" {
  length  = 8
  special = false
  upper   = false
}

locals {
  environment_id = "qa-${random_string.environment_id.result}"
}

# Create QA environment workspace
resource "tfe_workspace" "qa_environment" {
  name         = local.environment_id
  organization = var.organization_name
  
  description = "Disposable QA environment for testing"
  
  # Workspace settings
  auto_apply = false
  queue_all_runs = false
  
  # Terraform version
  terraform_version = "1.5.0"
  
  # Tags for organization
  tag_names = ["qa", "disposable"]
}

# Create workspace variables
resource "tfe_variable" "environment_name" {
  key          = "environment_name"
  value        = local.environment_id
  category     = "terraform"
  workspace_id = tfe_workspace.qa_environment.id
  description  = "Environment identifier"
}

resource "tfe_variable" "instance_type" {
  key          = "instance_type"
  value        = "t3.micro"
  category     = "terraform"
  workspace_id = tfe_workspace.qa_environment.id
  description  = "EC2 instance type"
}

# Sensitive variables
resource "tfe_variable" "aws_access_key" {
  key          = "AWS_ACCESS_KEY_ID"
  value        = var.aws_access_key_id
  category     = "env"
  sensitive    = true
  workspace_id = tfe_workspace.qa_environment.id
  description  = "AWS Access Key ID"
}

resource "tfe_variable" "aws_secret_key" {
  key          = "AWS_SECRET_ACCESS_KEY"
  value        = var.aws_secret_access_key
  category     = "env"
  sensitive    = true
  workspace_id = tfe_workspace.qa_environment.id
  description  = "AWS Secret Access Key"
}

resource "tfe_variable" "aws_region" {
  key          = "AWS_REGION"
  value        = "us-west-1"
  category     = "env"
  workspace_id = tfe_workspace.qa_environment.id
  description  = "AWS Region"
}

# Outputs
output "workspace_name" {
  value = tfe_workspace.qa_environment.name
}

output "workspace_url" {
  value = "https://app.terraform.io/app/${var.organization_name}/workspaces/${tfe_workspace.qa_environment.name}"
}

output "environment_id" {
  value = local.environment_id
}
