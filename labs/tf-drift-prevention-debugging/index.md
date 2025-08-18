# Terraform Drift prevention and HCP Terraform Debugging

## Overview

In this lab, you will learn about infrastructure drift prevention in HCP Terraform, how to prevent drift using Terraform tests, and how to debug common HCP Terraform workspace issues. You'll also learn to interpret error messages and apply best practices for error prevention.

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

Update your `main.tf` to use the remote EC2 instance module from HCP Terraform, also remove the s3_bucket module:

```hcl
# main.tf

# Use remote module from HCP Terraform
module "ec2_instances" {
  source  = "app.terraform.io/<Your-Org>/ec2-instance-tests-{your-initials}/aws"
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

<!-- delete this -->
module "s3_bucket" {
  source      = "app.terraform.io/<Your-Org>/s3-bucket-{your-initials}/aws"
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

### 4. Automatic Plan via VCS Integration

Since VCS integration is configured, pushing your changes will automatically trigger a plan and apply in HCP Terraform:

**Expected Result:** The plan should succeed and show the infrastructure that will be created.

### 5. Apply the Configuration

1. Click "Confirm & Apply" to apply the configuration
2. Wait for the apply to complete

**Expected Result:** Your infrastructure should be deployed successfully.

### 6. Understand Drift Prevention

Let's focus on preventing it through proper configuration and testing. Drift occurs when infrastructure is modified outside of Terraform, such as:

- Manual changes in the cloud console
- Changes by other automation tools
- Resource modifications by other team members
- Cloud provider maintenance or updates

To prevent drift, we'll implement several strategies:

1. **Comprehensive tagging policies** - Ensure all resources have consistent tags
2. **Resource locking** - Prevent manual modifications to critical resources
3. **Regular monitoring** - Set up alerts for unexpected changes
4. **Access controls** - Limit who can modify infrastructure outside of Terraform

### 7. Add Drift Prevention Tests to the Module

Navigate to your `terraform-aws-ec2-instance-tests-{your-initials}` module repository:

```sh
cd ../terraform-aws-ec2-instance-tests-{your-initials}
```

Add the following to your tests/integration.tftest.hcl file to validate that EC2 instances have the required project tag:

```hcl
# tests/integration.tftest.hcl
run "validate_ec2_instance_tags" {
  command = apply

  variables {
    instance_count = 2
    instance_type  = "t2.micro"
    subnet_ids     = [run.setup_infrastructure.subnet_id]
    security_group_ids = [run.setup_infrastructure.security_group_id]
    tags = {
      environment = "dev"
    }
  }

  # Test that instances have project tag
  assert {
    condition     = alltrue([for instance in aws_instance.app : contains(keys(instance.tags), "project")])
    error_message = "All EC2 instances must have project tag"
  }
}
```

### 8. Commit and Push Module Tests

```sh
git add .
git commit -m "Add drift prevention test for EC2 instance tags"
git push
```

### 9. Watch the Test Fail

1. Go to the HCP Terraform module registry
2. Select the `ec2-instance-tests-{your-initials}` module
3. Navigate to the "Tests" tab
4. Watch the test run automatically through VCS integration

**Expected Result:** The test should fail because the `project` tag is missing from the variables.

### 10. Fix the Test by Adding the Project Tag

Update the test variables to include the project tag:

```hcl
# Update tests/integration.tftest.hcl
run "validate_ec2_instance_tags" {
  command = apply

  variables {
    instance_count = 2
    instance_type  = "t2.micro"
    subnet_ids     = [run.setup_infrastructure.subnet_id]
    security_group_ids = [run.setup_infrastructure.security_group_id]
    tags = {
      project     = "project-alpha"
      environment = "dev"
    }
  }

  # Test that instances have project tag
  assert {
    condition     = alltrue([for instance in aws_instance.app : contains(keys(instance.tags), "project")])
    error_message = "All EC2 instances must have project tag"
  }
}
```

Commit and push the fix:

```sh
git add .
git commit -m "Add project tag to fix failing test"
git push
```

**Expected Result:** The test should now pass in HCP Terraform's module registry.

### 11. Add a Second Test (After First Test Passes)

Once your first test passes in HCP Terraform, add a second test to validate that instances have the correct instance type:

```hcl
# Add this to tests/integration.tftest.hcl
run "validate_ec2_instance_type" {
  command = apply

  variables {
    instance_count = 2
    instance_type  = "t3.small"
    subnet_ids     = [run.setup_infrastructure.subnet_id]
    security_group_ids = [run.setup_infrastructure.security_group_id]
    tags = {
      project     = "project-alpha"
      environment = "dev"
    }
  }

  # Test that all instances have the correct instance type
  assert {
    condition     = alltrue([for instance in aws_instance.app : instance.instance_type == "t2.micro"])
    error_message = "All EC2 instances must be t2.micro type"
  }
}
```

Commit and push the updated tests:

```sh
git add .
git commit -m "Add instance type validation test"
git push
```

**Expected Result:** The test will fail because instances are created as t3.small but the test expects t2.micro.

### 12. Fix the Test

Revert the instance type back to t2.micro:

```hcl
# Fix the test by restoring instance_type = "t2.micro"
variables {
  instance_count = 2
  instance_type  = "t2.micro"  # Back to the correct value
  # ... rest of variables
}
```

Commit and push the fix:

```sh
git add .
git commit -m "Fix test by restoring instance type to t2.micro"
git push
```

**Expected Result:** The test should now pass again.

### 13. Apply Test Assertions to Module Variables

Now that we've tested our module, we can add these same validation rules directly to the module variables to prevent invalid configurations from being applied in the first place.

Update the `variables.tf` file in the module to add validation blocks using the exact same logic from our tests:

```hcl
# variables.tf in terraform-aws-ec2-instance-tests-{your-initials}
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  
  validation {
    condition     = var.instance_type == "t2.micro"
    error_message = "All EC2 instances must be t2.micro type"
  }
}

variable "tags" {
  description = "Tags for the EC2 instances"
  type        = map(string)
  
  validation {
    condition     = contains(keys(var.tags), "project")
    error_message = "All EC2 instances must have project tag"
  }
}
```

Commit and push the module with validations:

```sh
git add .
git commit -m "Add variable validations to prevent invalid configurations"
git push
```

### 14. Fix Existing Integration Tests

**Important:** Adding validation rules to the module variables will cause **all existing integration tests to fail** because they don't have the correct tags and instance types.

You'll see errors like:
```
Error: Invalid value for variable
on tests/integration.tftest.hcl line 41, in run "test_instance_count_variable":
    instance_type  = "t2.small"
var.instance_type is "t2.small"
All EC2 instances must be t2.micro type
```

Update all integration tests in `tests/integration.tftest.hcl` to use the correct values. For instance, test_ec2_instance_creation and test_instance_count_variable need to be updated with the correct tags and instance type.

```

Commit and push the test fixes:

```sh
git add .
git commit -m "Fix integration tests to comply with new variable validations"
git push
```

### 15. Create New Module Version

Now we need to create a new version tag for the module since we've added breaking changes (validation rules):

```sh
# Create a new version tag
git tag v1.1.0
git push origin v1.1.0
```

This will automatically publish the new version to the HCP Terraform module registry.

### 16. Publish New Version in HCP Terraform UI

1. Go to HCP Terraform module registry
2. Navigate to your `ec2-instance-tests-{your-initials}` module
3. Click "Publish new version"
4. Select the latest commit (the one with "Add variable validations to prevent invalid configurations")
5. Type "1.1.0" as the version number
6. Click "Publish version"

This ensures the new version with validation rules is available in the module registry.

### 17. Test Variable Validations in Consuming Repository

Now navigate to the consuming repository and test the validations:

```sh
cd ../learn-terraform-variables
```

Temporarily modify the module call in `main.tf` to use the new module tag, and use invalid values (same ones that failed our tests):

```hcl
# Temporarily modify the module call in main.tf
module "ec2_instances" {
  source  = "app.terraform.io/<Your-Org>/ec2-instance-tests-{your-initials}/aws"
  version = "1.1.0"

  instance_count     = var.instance_count
  instance_type      = "t3.small"  # This will trigger validation error (must be t2.micro)
  subnet_ids         = module.vpc.private_subnets[*]
  security_group_ids = [module.app_security_group.this_security_group_id]

  tags = {
    environment = "dev"  # Missing project tag - this will trigger validation error
  }
}
```

### 18. Push and Watch Plan Fail

Commit and push the invalid configuration:

```sh
git add .
git commit -m "Test: Use invalid values to trigger validation errors"
git push
```

**Expected Result:** The plan should fail with validation errors like:
- "All EC2 instances must be t2.micro type"
- "All EC2 instances must have project tag"

### 19. Fix the Configuration

Revert the module call back to valid values (same ones that passed our tests):

```hcl
# Fix the module call in main.tf
module "ec2_instances" {
  source  = "app.terraform.io/<Your-Org>/ec2-instance-tests-{your-initials}/aws"
  version = "1.1.0"

  instance_count     = 2
  instance_type      = "t2.micro"  # Valid value
  subnet_ids         = module.vpc.private_subnets[*]
  security_group_ids = [module.app_security_group.this_security_group_id]

  tags = {
    project     = "project-alpha"  # Valid value
    environment = "dev"
  }
}
```

Commit and push the fix:

```sh
git add .
git commit -m "Fix: Use valid values for instance configuration"
git push
```

**Expected Result:** The plan should now succeed with the valid configuration.

This approach prevents drift by:
- **Validating at plan time** - Invalid configurations fail before they're applied
- **Enforcing business rules** - Only allowed instance types and counts can be used
- **Preventing configuration drift** - Users can't accidentally specify invalid values

### 20. Document Debugging Procedures

Create a debugging guide for your team:

```markdown
# HCP Terraform Debugging Guide

## Debugging Workflow

1. **Identify Error Type**: Categorize the error based on error message
2. **Check Logs**: Review detailed logs in HCP Terraform
3. **Validate Configuration**: Test configuration locally if possible
4. **Apply Fix**: Make necessary changes
5. **Test Fix**: Run tests to validate the fix
6. **Document**: Update debugging guide with new findings
```

## Expected Results

- Successfully implement comprehensive drift prevention strategies
- Create and run drift prevention tests
- Debug and resolve common HCP Terraform errors
- Establish best practices for error prevention
- Create monitoring and alerting for workspace issues

## Benefits of Drift Prevention and Debugging

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

- **Reflection:** How does implementing drift prevention and comprehensive debugging procedures improve the reliability of your infrastructure deployments? What are the trade-offs between automated testing and manual intervention?

## Key Concepts Covered

- **Drift Prevention:** Understanding and preventing infrastructure drift
- **Test-Driven Prevention:** Using tests to prevent drift and errors
- **Error Classification:** Categorizing and understanding different error types
- **Debugging Workflows:** Systematic approaches to problem resolution
- **Best Practices:** Establishing procedures for error prevention

## Next Steps

After completing this lab, you can:
- Implement drift prevention in your production environments
- Create comprehensive test suites for all infrastructure components
- Establish monitoring and alerting for workspace issues
- Develop team-specific debugging procedures
- Integrate error prevention into your CI/CD pipeline

## Additional Resources

- [HCP Terraform Drift Detection](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/state/drift-detection)
- [Terraform Testing Framework](https://developer.hashicorp.com/terraform/language/tests)
- [HCP Terraform Error Messages](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/state/error-messages)
- [Terraform Best Practices](https://developer.hashicorp.com/terraform/cloud-docs/recommended-practices) 