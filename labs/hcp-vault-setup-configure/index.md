# HCP Vault Setup and Configuration

## Overview

In this lab, you will learn how to set up and configure HashiCorp Cloud Platform (HCP) Vault Dedicated, a fully managed Vault Enterprise service. You'll create a Vault cluster, configure basic settings, and understand the key concepts of HCP Vault.

This lab builds upon the previous labs and demonstrates how to integrate Vault with your infrastructure automation workflows.

## Prerequisites

This lab builds upon the previous labs. You should have completed:
- `tf-setup` - Basic Terraform setup and configuration
- `tf-variables-and-output` - Understanding Terraform variables and outputs
- `hcp-tf-setup` - HCP Terraform workspace setup

You should be familiar with:
- HCP Terraform workspaces and VCS integration
- Basic Terraform concepts and syntax
- Cloud provider resources (AWS, Azure, or GCP)

## Part 1: Understanding HCP Vault

### What is HCP Vault Dedicated?

HCP Vault Dedicated is a fully managed Vault Enterprise service that enables you to deploy a Vault cluster in a supported public cloud provider. As a managed service, you can use Vault as a central secret management service while offloading the operational burden to HashiCorp's Site Reliability Engineering (SRE) experts.

**Key Benefits:**
- Fully managed Vault Enterprise cluster
- Automatic updates and maintenance
- Built-in high availability and disaster recovery
- Integration with HCP Terraform and other HashiCorp tools
- Enterprise features without operational overhead

### HCP Vault vs. Self-Managed Vault

| Feature | HCP Vault Dedicated | Self-Managed Vault |
|---------|-------------------|-------------------|
| Deployment | Fully managed | Self-deployed |
| Updates | Automatic | Manual |
| High Availability | Built-in | Manual configuration |
| Monitoring | Integrated | Self-configured |
| Support | HashiCorp SRE team | Self-supported |

## Part 2: Creating an HCP Vault Cluster

### Step 1: Access HCP Portal

1. Navigate to the [HCP Portal](https://portal.cloud.hashicorp.com)
2. Log in with your HashiCorp account
3. Select your organization from the organization list

### Step 2: Create a Project

1. Click **Projects** in the navigation
2. Click **+ Create project**
3. Enter the following details:
   - **Project name**: `vault-lab-{your-initials}` (e.g., `vault-lab-js`)
   - **Project description**: `HCP Vault setup and configuration lab`
4. Click **Create project**

### Step 3: Deploy Vault Cluster

1. From the project overview page, click **Vault Dedicated - Get started with Vault Dedicated**
2. On the Vault overview page, click **Create cluster** under **Start from scratch**
3. Select your preferred cloud provider (AWS, Azure, or GCP)
4. Configure the cluster settings:
   - **Vault tier**: Development
   - **Cluster size**: Extra Small
   - **Network ID**: `hvn-{your-initials}` (e.g., `hvn-js`)
   - **Region**: Accept default
   - **CIDR block**: Accept default
5. Under **Basics**, set the **Cluster ID** to `vault-lab-cluster-{your-initials}` (e.g., `vault-lab-cluster-js`)
6. Under **Templates**, select **Start from scratch**
7. Click **Create cluster**

### Step 4: Wait for Cluster Initialization

The cluster creation process typically takes 5-10 minutes. You can monitor the progress on the cluster overview page.

## Part 3: Accessing Your HCP Vault Cluster

### Security Considerations

When an HCP Vault Dedicated cluster has **public** access enabled, you can connect to Vault from any internet-connected device. If your use case requires public access, we recommend configuring the **IP allow list** to limit which IPv4 public IP addresses or CIDR ranges can connect to Vault.

When the HCP Vault Dedicated cluster has **private** access enabled, you will need to access the cluster from a connected cloud provider such as AWS with a VPC peering connection, an AWS transit gateway connection, or Azure with an Azure Virtual Network peering connection. For the purposes of this tutorial, your cluster should have public access enabled.

### Method 1: Web UI Access

1. From the **Overview** page, click **Generate token** in the **New admin token** card
2. Click **Copy** to copy the new token to your clipboard
3. Click **Launch web UI**
4. When the Vault UI launches in a new tab/window, enter the token in the **Token** field
5. Click **Sign In**

Notice that your current namespace is `admin/`.

<!-- ### Method 2: CLI Access

**Prerequisite:** Install Vault CLI by following the [Install Vault guide](https://developer.hashicorp.com/vault/docs/install)

1. Under **Quick actions**, click **Public** Cluster URL
2. In a terminal, set the `VAULT_ADDR` environment variable:
   ```bash
   export VAULT_ADDR=<Public_Cluster_URL>
   ```
3. Verify your connectivity to the Vault cluster:
   ```bash
   vault status
   ```
   Expected output:
   ```
   Key                      Value
   ---                      -----
   Recovery Seal Type       shamir
   Initialized              true
   Sealed                   false
   Total Recovery Shares    1
   Threshold                1
   Version                  1.6.0+ent
   Storage Type             raft
   ```
4. Return to the **Overview** page and click **Generate token**
5. Copy the **Admin Token**
6. Return to the terminal and log in with Vault:
   ```bash
   vault login
   Token (will be hidden): <token>
   ```
7. View the current token configuration:
   ```bash
   vault token lookup
   ```
   Notice that `namespace_path` is `admin/`. This indicates that you are logged into the `admin` namespace.
8. Set the `VAULT_NAMESPACE` environment variable:
   ```bash
   export VAULT_NAMESPACE="admin"
   ```

### Method 3: API Access with cURL

**Prerequisite:** Install `jq` for JSON processing

1. Under **Quick actions**, click the **Public** Cluster URL
2. In a terminal, set the `VAULT_ADDR` environment variable:
   ```bash
   export VAULT_ADDR=<Public_Cluster_URL>
   ```
3. Return to the **Overview** page and click **Generate token**
4. Copy the **Admin Token**
5. Set the `VAULT_TOKEN` environment variable:
   ```bash
   export VAULT_TOKEN=<token>
   ```
6. Verify connectivity using one of these methods:

   **Option 1:** Specify the target namespace in the `X-Vault-Namespace` header:
   ```bash
   curl --header "X-Vault-Token: $VAULT_TOKEN" \
      --header "X-Vault-Namespace: admin" \
      $VAULT_ADDR/v1/auth/token/lookup-self | jq -r ".data"
   ```

   **Option 2:** Use environment variable for namespace:
   ```bash
   export VAULT_NAMESPACE=admin
   curl --header "X-Vault-Token: $VAULT_TOKEN" \
      --header "X-Vault-Namespace: $VAULT_NAMESPACE" \
      $VAULT_ADDR/v1/auth/token/lookup-self | jq -r ".data"
   ```

   **Option 3:** Prepend the API endpoint with namespace:
   ```bash
   curl --header "X-Vault-Token: $VAULT_TOKEN" \
      $VAULT_ADDR/v1/admin/auth/token/lookup-self | jq -r ".data"
   ``` -->

## Part 4: Configuring HCP Vault

## Part 1: Basic Vault Operations

### Step 1: Enable KV Secrets Engine

1. In the Vault UI, navigate to **Secrets** → **Enable new engine**
2. Select **KV** (Key-Value) from the list
3. Configure the KV engine:
   - **Path**: `kv-{your-initials}` (e.g., `kv-js`)
   - **Everything else**: Accept defaults
4. Click **Enable Engine**

### Step 2: Store AWS Credentials

1. Navigate to the **kv-{your-initials}** engine
2. Click **Create secret**
3. Create a secret for AWS credentials:
   - **Path**: `aws/credentials`
   - **Key**: `access_key_id`
   - **Value**: Your AWS access key
4. Click **Save**
5. Create another secret:
   - **Path**: `aws/credentials`
   - **Key**: `secret_access_key`
   - **Value**: Your AWS secret key
6. Click **Save**

## Part 7: Integration with HCP Terraform

### Step 1: Get Vault Cluster URL

1. In HCP, navigate to your Vault cluster overview
2. Go to the **Overview** page
3. In the **Quick actions** pane, click **Public** Cluster URL
4. Copy the URL (it will look like: `https://vault-cluster-xxxxx.region.hashicorp.cloud`)

### Step 2: Add Vault Provider Configuration

In your existing `learn-terraform-variables` repository, update the `main.tf` file:

First, add Vault to the `required_providers` block (around line 8):

```hcl
# Update the existing required_providers block in main.tf
required_providers {
  aws = {
    source = "hashicorp/aws"
    version = "~> 3.76.0"
  }
  vault = {
    source  = "hashicorp/vault"
    version = "~> 4.0"
  }
}
```

Then, update the existing Vault provider block (around line 20):

```hcl
# Update the existing provider "vault" block in main.tf
provider "vault" {
  address = "https://your-actual-vault-cluster-url"  # Replace with your cluster URL
  token   = var.vault_token
}
```

Add the vault_token variable to `variables.tf`:

```hcl
# Add to variables.tf
variable "vault_token" {
  description = "Vault admin token"
  type        = string
  sensitive   = true
}
```

### Step 3: Use AWS Credentials from Vault

Add the following to your `main.tf` file to retrieve AWS credentials from Vault:

```hcl
# Add this data source to main.tf (after the provider blocks, around line 25)
data "vault_kv_secret_v2" "aws_creds" {
  mount = "kv-{your-initials}"
  name  = "aws/credentials"
}

# Update the existing provider "aws" block in main.tf (around line 17)
provider "aws" {
  region     = "us-west-1"  # Keep existing region
  access_key = data.vault_kv_secret_v2.aws_creds.data["access_key_id"]
  secret_key = data.vault_kv_secret_v2.aws_creds.data["secret_access_key"]
}
```

### Step 4: Get Vault Token

1. In your HCP Vault cluster, navigate to the **Overview** page
2. In the **Quick actions** pane, click **Generate token**
3. Copy the generated admin token (you'll need this for Terraform access)

### Step 5: Update HCP Terraform Workspace Variables

1. In your existing HCP Terraform workspace for `learn-terraform-variables` (already connected via VCS)
2. Go to the **Variables** page
3. Remove any existing AWS credential variables (like `aws_access_key_id`, `aws_secret_access_key`)
4. Add a new variable:
   - **Key**: `vault_token`
   - **Value**: Paste the Vault admin token you generated
   - **Sensitive**: Check this box
5. Save the variable

### Step 6: Deploy with HCP Terraform

1. Commit and push your changes to trigger a new run via VCS integration

## Expected Results

- Successfully created an HCP Vault Dedicated cluster
- Configured network access and security settings
- Accessed Vault through multiple methods (UI, CLI, API)
- Performed basic Vault operations (stored AWS credentials in KV secrets)
- Integrated Vault with HCP Terraform for automated AWS credential retrieval
- Understanding of HCP Vault's managed service benefits

## Benefits of HCP Vault Integration

### 1. **Centralized Secrets Management**
- Single source of truth for all secrets
- Consistent access patterns across applications
- Automated secret rotation and lifecycle management

### 2. **Enhanced Security**
- Encryption at rest and in transit
- Fine-grained access control policies
- Comprehensive audit logging
- Integration with existing identity providers

### 3. **Operational Efficiency**
- No infrastructure management overhead
- Automatic updates and maintenance
- Built-in high availability
- Professional support and monitoring

## Reflection

- **Reflection:** How does using HCP Vault Dedicated change your approach to secrets management compared to self-managed solutions? What are the trade-offs between managed services and self-hosted infrastructure?

## Key Concepts Covered

- **HCP Vault Dedicated:** Understanding managed Vault services
- **Cluster Creation:** Setting up Vault clusters in HCP
- **Cluster Access:** Multiple methods for accessing Vault (UI, CLI, API)
- **Network Configuration:** Securing Vault access
- **Basic Operations:** Creating and managing secrets
- **Terraform Integration:** Automating Vault operations
- **Security Best Practices:** Implementing proper access controls

## Next Steps

After completing this lab, you can:
- Configure authentication methods (LDAP, OIDC, etc.)
- Set up dynamic secrets for databases and cloud services
- Implement Vault policies for access control
- Integrate Vault with your application deployment pipelines
- Explore advanced features like transit encryption and PKI

## Additional Resources

- [HCP Vault Documentation](https://developer.hashicorp.com/vault/docs)
- [Vault Provider for Terraform](https://registry.terraform.io/providers/hashicorp/vault/latest/docs)
- [HCP Vault Best Practices](https://developer.hashicorp.com/vault/docs/best-practices)
- [Vault API Reference](https://developer.hashicorp.com/vault/api-docs) 