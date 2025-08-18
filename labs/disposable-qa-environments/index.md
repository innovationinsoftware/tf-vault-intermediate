# Creating Disposable QA Environments with HCP Terraform

## Overview

In this lab, you will learn how to create disposable QA environments using HCP Terraform workspaces. You'll use the TFE provider to create workspaces programmatically and demonstrate how to spin them up and down for testing purposes.

## Prerequisites

This lab builds upon the previous labs. You should have completed:
- `hcp-tf-setup` - HCP Terraform authentication and workspace setup
- `hcp-vault-setup-configure` - HCP Vault setup and configuration

You should be familiar with:
- HCP Terraform workspace management
- Basic Terraform configuration

## Lab Objectives

By the end of this lab, you will be able to:
- Use the TFE provider to create HCP Terraform workspaces
- Configure workspace variables programmatically
- Create and destroy QA environment workspaces
- Understand workspace lifecycle management

## Part 1: Understanding Disposable QA Environments

### What are Disposable QA Environments?

Disposable QA environments are temporary workspaces that:
- **Create isolated infrastructure** for testing
- **Automatically provision** resources when needed
- **Easy cleanup** by destroying the entire workspace
- **Consistent configuration** across environments

### Benefits

1. **Isolation**: Each environment has its own state and resources
2. **Cleanup**: Destroy workspace = destroy all resources
3. **Consistency**: Same configuration every time
4. **Cost Control**: Only pay for resources when testing

## Part 2: Setup TFE Provider

### Step 1: Create Workspace Management Repository

1. Create a new GitHub repository named `qa-workspace-manager-{your-initials}`
2. Clone the repository locally:

```sh
git clone https://github.com/YOUR_USERNAME/qa-workspace-manager-{your-initials}
cd qa-workspace-manager-{your-initials}
```

### Step 2: Copy the Configuration Files

The lab includes the following Terraform files. Copy them to your repository:

- `main.tf` - Main workspace management configuration
- `variables.tf` - Variables for workspace management
- `environments/qa/main.tf` - QA environment infrastructure  
- `environments/qa/variables.tf` - Variables for QA environment

### Step 3: Review the Configuration

The configuration files are already provided in the lab directory. Review them to understand:

- How the TFE provider is configured
- How workspace variables are set up
- The structure of the QA environment infrastructure

## Part 3: QA Environment Infrastructure

The QA environment infrastructure is already configured in the `environments/qa/` directory. This includes:

- A simple EC2 instance for QA testing
- Proper tagging for resource identification
- Outputs for instance ID and environment ID

## Part 4: Test the Disposable Environment

### Step 1: Create QA Environment

1. Set up your local environment variables:

```sh
export TF_VAR_tfe_token="your-hcp-terraform-token"
export TF_VAR_organization_name="your-organization-name"
export TF_VAR_aws_access_key_id="your-aws-access-key"
export TF_VAR_aws_secret_access_key="your-aws-secret-key"
```

2. Initialize and apply:

```sh
terraform init
terraform plan
terraform apply
```

### Step 2: Verify Workspace Creation

1. Go to HCP Terraform at https://app.terraform.io
2. Navigate to your organization
3. Verify the new workspace is created with the random name
4. Check that variables are configured

### Step 3: Deploy Infrastructure

1. Go to the created workspace
2. Click "Queue plan"
3. Review the plan and apply
4. Verify the EC2 instance is created

### Step 4: Cleanup

1. Go back to your local terminal
2. Destroy the workspace:

```sh
terraform destroy
```

3. Verify the workspace is removed from HCP Terraform

## Expected Results

By the end of this lab, you should have:
- Successfully created a QA environment workspace using the TFE provider
- Configured workspace variables programmatically
- Deployed simple infrastructure in the workspace
- Destroyed the workspace and all associated resources
- Understood the basic workflow for disposable environments

## Key Concepts Covered

- **TFE Provider**: Using Terraform to manage HCP Terraform workspaces
- **Workspace Management**: Creating and configuring workspaces programmatically
- **Variable Configuration**: Setting up workspace variables with Terraform
- **Lifecycle Management**: Creating and destroying disposable environments
- **State Isolation**: Each workspace has its own Terraform state

## Next Steps

After completing this lab, you can:
- Add more complex infrastructure configurations
- Implement VCS integration for workspaces
- Add HCP Vault integration for secrets management
- Create multiple environment types
- Implement automated workflows with CI/CD
