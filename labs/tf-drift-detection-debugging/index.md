# Terraform Drift Detection and HCP Terraform Debugging

## Overview

In this lab, you will learn about infrastructure drift detection in HCP Terraform, how to prevent drift using Terraform tests, and how to debug common HCP Terraform workspace issues. You'll also learn to interpret error messages and apply best practices for error prevention.

This lab builds upon the existing `learn-terraform-variables` repository and demonstrates real-world scenarios for managing infrastructure consistency and troubleshooting deployment issues.

## Prerequisites

This lab builds upon the previous labs. You should have completed:
- `tf-unit-testing` - Unit testing with local mocking
- `tf-integration-testing` - Integration testing with HCP Terraform
- `tf-checkov-security` - Security scanning with Checkov

You should be familiar with:
- HCP Terraform workspaces and VCS integration
- Terraform testing framework
- AWS resources and configurations
- Basic troubleshooting concepts

## Part 1: Drift Detection and Prevention

### 1. Prepare the Repository

First, let's clean up the repository and use the remote module from HCP Terraform:

```sh
cd learn-terraform-variables
```

Remove the local modules directory:

```sh
rm -rf modules/
```

### 2. Update Configuration to Use Remote Module

Update your `main.tf` to use the remote EC2 instance module from HCP Terraform, also uncomment the s3_bucket module:

```hcl
# main.tf

# Use remote module from HCP Terraform
module "ec2_instances" {
  source  = "app.terraform.io/sudo-cloud-org/ec2-instance/aws"
  version = "1.0.0"

  instance_count     = var.instance_count
  instance_type      = var.instance_type
  subnet_ids         = module.vpc.private_subnets[*]
  security_group_ids = [module.app_security_group.this_security_group_id]

  tags = {
    project     = "project-alpha"
    environment = "dev"
  }
}

module "s3_bucket" {
  source      = "app.terraform.io/sudo-cloud-org/s3-bucket/aws"
  version     = "1.0.0"
  bucket_name = "my-bucket"
}
```

### 3. Commit and Push Changes

```sh
git add .
git commit -m "Update to use remote EC2 instance module from HCP Terraform"
git push
```

### 4. Trigger a Plan in HCP Terraform

1. Go to your HCP Terraform workspace
2. Click "Queue plan" to trigger a new plan
3. Wait for the plan to complete

**Expected Result:** The plan should succeed and show the infrastructure that will be created.

### 5. Apply the Configuration

1. Click "Confirm & Apply" to apply the configuration
2. Wait for the apply to complete

**Expected Result:** Your infrastructure should be deployed successfully.

### 6. Simulate Infrastructure Drift

Now let's simulate infrastructure drift by manually modifying a resource outside of Terraform:

1. Go to the AWS Console
2. Navigate to EC2 > Instances
3. Select one of the instances created by Terraform
4. Add a tag: `drift-test = "manual-change"`
5. Save the changes

### 7. Detect Drift

1. Go back to your HCP Terraform workspace
2. Click "Queue plan" to trigger a new plan
3. Wait for the plan to complete

**Expected Result:** You should see a drift detection message indicating that the infrastructure has drifted from the expected state.

### 8. Create Drift Prevention Tests

Create a test file to prevent future drift:

```hcl
# tests/drift_prevention.tftest.hcl
run "prevent_ec2_instance_drift" {
  command = plan

  variables {
    instance_count = 2
    instance_type  = "t2.micro"
  }

  # Test that instances have correct tags
  assert {
    condition     = alltrue([for instance in module.ec2_instances.instances : contains(keys(instance.tags), "project")])
    error_message = "All EC2 instances must have project tag"
  }

  assert {
    condition     = alltrue([for instance in module.ec2_instances.instances : contains(keys(instance.tags), "environment")])
    error_message = "All EC2 instances must have environment tag"
  }

  # Test that instances are in correct subnets
  assert {
    condition     = alltrue([for instance in module.ec2_instances.instances : contains(var.subnet_ids, instance.subnet_id)])
    error_message = "All EC2 instances must be in specified subnets"
  }
}

run "prevent_security_group_drift" {
  command = plan

  variables {
    instance_count = 2
    instance_type  = "t2.micro"
  }

  # Test that security groups are properly configured
  assert {
    condition     = length(module.app_security_group.this_security_group_id) > 0
    error_message = "Security group must be created"
  }
}
```

### 9. Run Drift Prevention Tests

```sh
terraform test tests/drift_prevention.tftest.hcl
```

**Expected Result:** The tests should pass, validating that your configuration prevents common drift scenarios.

## Part 2: HCP Terraform Debugging

### 10. Force Common Errors for Debugging Practice

Let's intentionally introduce errors to practice debugging:

#### Error 1: Invalid Variable Value

Update your `variables.tf` to add a validation rule:

```hcl
# variables.tf
variable "instance_count" {
  description = "Number of EC2 instances to deploy"
  type        = number
  default     = 2

  validation {
    condition     = var.instance_count > 0 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10."
  }
}

variable "instance_type" {
  description = "Type of EC2 instance to use"
  type        = string
  default     = "t2.micro"

  validation {
    condition     = can(regex("^t[23]\\.[a-z]+$", var.instance_type))
    error_message = "Instance type must be a valid t2 or t3 instance type."
  }
}
```

Now, let's force an error by setting an invalid instance count:

```sh
# Temporarily modify main.tf to use invalid value
# Change instance_count = var.instance_count to instance_count = 15
```

#### Error 2: Module Version Conflict

Update the EC2 module to use a non-existent version:

```hcl
# Temporarily change the module version to force an error
module "ec2_instances" {
  source  = "app.terraform.io/sudo-cloud-org/ec2-instance/aws"
  version = "999.0.0"  # This version doesn't exist
  # ... rest of configuration
}
```

#### Error 3: Provider Configuration Issue

Add an invalid provider configuration:

```hcl
# Temporarily add this to main.tf to force a provider error
provider "aws" {
  region = "invalid-region"
}
```

### 11. Debug Error Messages

For each error, commit and push the changes, then observe the error messages in HCP Terraform:

```sh
git add .
git commit -m "Force error for debugging practice"
git push
```

#### Understanding Error Messages

**Variable Validation Error:**
```
Error: Invalid value for variable
  on main.tf line XX, in module "ec2_instances":
   XX:   instance_count = 15
Instance count must be between 1 and 10.
```

**Module Version Error:**
```
Error: Failed to query available versions for module
  on main.tf line XX, in module "ec2_instances":
   XX:   source  = "app.terraform.io/sudo-cloud-org/ec2-instance/aws"
   XX:   version = "999.0.0"
No available versions found for the specified version constraint.
```

**Provider Configuration Error:**
```
Error: error configuring Terraform AWS Provider
  on main.tf line XX:
   XX: provider "aws" {
Invalid region: invalid-region
```

### 12. Fix the Errors

Revert the changes to fix the errors:

```hcl
# Restore the correct configuration
module "ec2_instances" {
  source  = "app.terraform.io/sudo-cloud-org/ec2-instance/aws"
  version = "1.0.0"

  instance_count     = var.instance_count
  instance_type      = var.instance_type
  subnet_ids         = module.vpc.private_subnets[*]
  security_group_ids = [module.app_security_group.this_security_group_id]

  tags = {
    project     = "project-alpha"
    environment = "dev"
  }
}

provider "aws" {
  region = "us-west-1"
}
```

### 13. Commit and Push Fixes

```sh
git add .
git commit -m "Fix debugging errors"
git push
```

### 14. Advanced Error Scenarios

#### Scenario 1: State Lock Issues

Simulate a state lock issue by running multiple applies simultaneously:

1. Start an apply in HCP Terraform
2. Quickly start another apply before the first completes
3. Observe the state lock error message

**Expected Error:**
```
Error: Error acquiring the state lock
Error message: resource already locked
Lock Info:
  ID:        xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
  Path:      organization/sudo-cloud-org/workspaces/policy-dev-an/terraform.tfstate
  Operation: OperationTypeApply
  Info:      Locked by: user@example.com
  Version:   0.0.0
  Created:   2024-01-01 12:00:00.000000000 +0000 UTC
```

#### Scenario 2: Dependency Cycle

Create a dependency cycle in your configuration:

```hcl
# Temporarily add this to create a dependency cycle
resource "aws_security_group_rule" "cycle" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = module.app_security_group.this_security_group_id
  source_security_group_id = aws_security_group_rule.cycle.id  # This creates a cycle
}
```

**Expected Error:**
```
Error: Cycle: aws_security_group_rule.cycle -> aws_security_group_rule.cycle
```

### 15. Best Practices for Error Prevention

Create a comprehensive test suite to prevent common errors:

```hcl
# tests/error_prevention.tftest.hcl
run "validate_variable_constraints" {
  command = plan

  variables {
    instance_count = 5
    instance_type  = "t3.micro"
  }

  # Test variable validation
  assert {
    condition     = var.instance_count >= 1 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10"
  }

  assert {
    condition     = can(regex("^t[23]\\.[a-z]+$", var.instance_type))
    error_message = "Instance type must be valid t2 or t3 type"
  }
}

run "validate_module_dependencies" {
  command = plan

  variables {
    instance_count = 2
    instance_type  = "t2.micro"
  }

  # Test that VPC exists before EC2 instances
  assert {
    condition     = length(module.vpc.vpc_id) > 0
    error_message = "VPC must be created before EC2 instances"
  }

  # Test that security groups exist
  assert {
    condition     = length(module.app_security_group.this_security_group_id) > 0
    error_message = "Security group must be created"
  }
}

run "validate_resource_configuration" {
  command = plan

  variables {
    instance_count = 2
    instance_type  = "t2.micro"
  }

  # Test that instances have required tags
  assert {
    condition     = alltrue([for instance in module.ec2_instances.instances : contains(keys(instance.tags), "project")])
    error_message = "All instances must have project tag"
  }

  # Test that instances are in private subnets
  assert {
    condition     = alltrue([for instance in module.ec2_instances.instances : contains(module.vpc.private_subnets, instance.subnet_id)])
    error_message = "All instances must be in private subnets"
  }
}
```

### 16. Run Error Prevention Tests

```sh
terraform test tests/error_prevention.tftest.hcl
```

### 17. Create Monitoring and Alerting

Set up workspace notifications in HCP Terraform:

1. Go to your workspace settings
2. Navigate to "Notifications"
3. Configure notifications for:
   - Plan failures
   - Apply failures
   - Drift detection
   - Policy violations

### 18. Document Debugging Procedures

Create a debugging guide for your team:

```markdown
# HCP Terraform Debugging Guide

## Common Error Types and Solutions

### 1. Variable Validation Errors
- **Error**: Invalid value for variable
- **Solution**: Check variable constraints and validation rules
- **Prevention**: Use comprehensive variable validation

### 2. Module Version Errors
- **Error**: Failed to query available versions
- **Solution**: Verify module exists and version is available
- **Prevention**: Pin module versions and test updates

### 3. Provider Configuration Errors
- **Error**: error configuring Terraform AWS Provider
- **Solution**: Check provider configuration and credentials
- **Prevention**: Use consistent provider configurations

### 4. State Lock Errors
- **Error**: Error acquiring the state lock
- **Solution**: Wait for lock to release or force unlock
- **Prevention**: Avoid concurrent operations

### 5. Dependency Cycle Errors
- **Error**: Cycle detected in resource dependencies
- **Solution**: Review resource dependencies and remove cycles
- **Prevention**: Use dependency testing

## Debugging Workflow

1. **Identify Error Type**: Categorize the error based on error message
2. **Check Logs**: Review detailed logs in HCP Terraform
3. **Validate Configuration**: Test configuration locally if possible
4. **Apply Fix**: Make necessary changes
5. **Test Fix**: Run tests to validate the fix
6. **Document**: Update debugging guide with new findings
```

## Expected Results

- Successfully detect and resolve infrastructure drift
- Implement comprehensive drift prevention tests
- Debug and resolve common HCP Terraform errors
- Establish best practices for error prevention
- Create monitoring and alerting for workspace issues

## Benefits of Drift Detection and Debugging

### 1. **Infrastructure Consistency**
- Maintains infrastructure in desired state
- Prevents configuration drift over time
- Ensures compliance with security policies

### 2. **Faster Problem Resolution**
- Systematic approach to error debugging
- Reduced time to identify and fix issues
- Improved team productivity

### 3. **Proactive Error Prevention**
- Catches issues before they reach production
- Reduces deployment failures
- Improves overall system reliability

## Reflection

- **Reflection:** How does implementing drift detection and comprehensive debugging procedures improve the reliability of your infrastructure deployments? What are the trade-offs between automated testing and manual intervention?

## Key Concepts Covered

- **Drift Detection:** Understanding and detecting infrastructure drift
- **Test-Driven Prevention:** Using tests to prevent drift and errors
- **Error Classification:** Categorizing and understanding different error types
- **Debugging Workflows:** Systematic approaches to problem resolution
- **Best Practices:** Establishing procedures for error prevention

## Next Steps

After completing this lab, you can:
- Implement drift detection in your production environments
- Create comprehensive test suites for all infrastructure components
- Establish monitoring and alerting for workspace issues
- Develop team-specific debugging procedures
- Integrate error prevention into your CI/CD pipeline

## Additional Resources

- [HCP Terraform Drift Detection](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/state/drift-detection)
- [Terraform Testing Framework](https://developer.hashicorp.com/terraform/language/tests)
- [HCP Terraform Error Messages](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/state/error-messages)
- [Terraform Best Practices](https://developer.hashicorp.com/terraform/cloud-docs/recommended-practices) 