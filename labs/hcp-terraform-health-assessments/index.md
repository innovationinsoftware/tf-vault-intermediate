# HCP Terraform Health Assessments

## Overview

In this lab, you will learn how to enable and configure health assessments in HCP Terraform. Health assessments provide automatic monitoring of your infrastructure to detect configuration drift and validate custom conditions. You'll explore enabling health assessments at both organization and workspace levels, understanding scheduling behavior, and learning how to resolve detected drift.

## Prerequisites

This lab builds upon the previous labs. You should have completed:
- `hcp-tf-setup` - HCP Terraform authentication and workspace setup
- `hcp-tf-modify` - Infrastructure modification and VCS workflow setup
- `hcp-tf-publish-module` - Module publishing and consumption

You should be familiar with:
- HCP Terraform workspace management
- Terraform configuration and state management
- Basic understanding of infrastructure drift

## Lab Objectives

By the end of this lab, you will be able to:
- Enable health assessments at workspace and organization levels
- Understand health assessment scheduling and timing
- Trigger on-demand health assessments
- Interpret health status indicators and results
- View and resolve configuration drift
- Configure continuous validation checks

## Part 1: Understanding Health Assessments

### What are Health Assessments?

Health assessments in HCP Terraform automatically evaluate whether your real infrastructure matches the requirements defined in your Terraform configuration. They include two main types of evaluations:

1. **Drift Detection**: Determines whether your real-world infrastructure matches your Terraform configuration
2. **Continuous Validation**: Determines whether custom conditions in your workspace's configuration continue to pass after Terraform provisions the infrastructure

### Health Assessment Requirements

Before enabling health assessments, ensure your workspace meets these requirements:
- Workspace must have a Terraform configuration
- Workspace must have access to the infrastructure it manages
- Workspace must have appropriate permissions for health assessment features

## Part 2: Enabling Health Assessments

### Step 1: Enable at Workspace Level

1. Sign in to HCP Terraform and navigate to your `tf-vault-qa-{your-initials}` workspace
2. Verify that your workspace satisfies the health assessment requirements:
   - Workspace has a Terraform configuration (EC2 instances)
   - Workspace has AWS credentials configured
   - Workspace has appropriate permissions
3. Go to the workspace and click **Settings**, then click **Health**
4. Select **Enable** under Health Assessments
5. Click **Save settings**

### Step 2: Enable at Organization Level (Optional)

Organization owners can enforce health assessments across all eligible workspaces:

1. Navigate to your HCP Terraform organization
2. Go to **Settings** → **General**
3. Find the Health Assessments section
4. Enable organization-wide health assessments

**Note**: Enforcing health assessments at the organization level overrides workspace-level settings.

## Part 3: Health Assessment Scheduling

### Understanding First Assessment Timing

When you enable health assessments, HCP Terraform automatically determines when to run the first assessment based on active Terraform runs:

- **No active runs**: Health assessment runs a few minutes after enabling the feature
- **Active speculative plan**: Health assessment runs a few minutes after that plan completes
- **Other active runs**: Health assessment runs during the next assessment period

### Assessment Periods

After the first health assessment, HCP Terraform starts a new health assessment during the next assessment period if there are no active runs in the workspace. Assessment periods are typically:
- Every 6 hours for most workspaces
- May vary based on workspace complexity and resource count

## Part 4: On-Demand Health Assessments

### Triggering Manual Assessments

On-demand health assessments allow administrators to manually trigger health evaluations:

1. Navigate to your `tf-vault-qa-{your-initials}` workspace's **Health** page
2. Ensure you have administrator permissions for the workspace
3. Verify the workspace satisfies all assessment requirements
4. Click **Start health assessment**

### On-Demand Assessment Behavior

- Only available in the HCP Terraform user interface
- Requires administrator permissions for the workspace
- Workspace must satisfy all assessment requirements
- Cannot trigger another assessment while one is in progress
- Resets the scheduling for automated assessments

## Part 5: Health Status Visibility

### Organization-Level Health Status

1. Navigate to your organization's **Workspaces** page
2. Look for **Health warning** status indicators for problematic workspaces
3. You should see your `tf-vault-qa-{your-initials}` workspace listed
4. Health warnings appear for workspaces with:
   - Infrastructure drift
   - Failed continuous validation checks

### Workspace-Level Health Status

1. Go to a specific workspace's overview page
2. Look for the **Health bar** on the right side of the page
3. The health bar summarizes the results of the last health assessment:
   - **Drift summary**: Shows total number of resources vs. drifted resources
   - **Checks summary**: Shows passed, failed, and unknown validation status counts

### Explorer View

1. Navigate to **Explorer** in your HCP Terraform organization
2. View condensed overview of health status across all workspaces:
   - Workspaces monitoring health
   - Status of configured continuous validation checks
   - Count of drifted resources for each workspace

## Part 6: Viewing and Resolving Drift

### Viewing Drift Detection Results

1. Navigate to your `tf-vault-qa-{your-initials}` workspace
2. Click **Health** → **Drift**
3. View the drift detection results from the latest health assessment
4. You should see your EC2 instances and their current state
5. If drift is detected, HCP Terraform shows the necessary changes to bring infrastructure back in sync

### Creating Intentional Drift (Optional)

To see drift detection in action, you can manually modify an EC2 instance in the AWS console:

1. Go to the AWS EC2 console
2. Find one of your instances created by the `tf-vault-qa-{your-initials}` workspace
3. Modify the instance type or add/remove tags
4. Return to HCP Terraform and trigger another health assessment
5. Observe how the drift is detected and reported

### Drift Resolution Approaches

When drift is detected, you have two main approaches to resolve it:

#### Approach 1: Overwrite Drift
If you don't want to keep the drift's changes:
1. Queue a new plan in your workspace
2. Apply the changes to revert your real-world infrastructure to match your Terraform configuration

#### Approach 2: Update Terraform Configuration
If you want to keep the drift's changes:
1. Modify your Terraform configuration to include the changes
2. Push a new configuration version
3. This prevents Terraform from reverting the drift during the next apply

## Part 7: Continuous Validation

### Understanding Continuous Validation

Continuous validation regularly verifies whether your configuration's custom assertions continue to pass, validating your infrastructure. Examples include:
- Monitoring website status codes
- Validating API gateway certificates
- Checking resource availability

### Configuring Check Blocks

Add check blocks to your Terraform configuration for continuous validation. In your `tf-vault-qa-{your-initials}` repository, you can add checks to validate your EC2 instances:

```hcl
check "ec2_instance_health" {
  data "aws_instance" "current" {
    instance_tags = {
      Name = "web-server-1"
    }
  }
  
  assert {
    condition     = data.aws_instance.current.instance_state == "running"
    error_message = "EC2 instance should be in running state"
  }
}

check "instance_type_validation" {
  data "aws_instance" "current" {
    instance_tags = {
      Name = "web-server-1"
    }
  }
  
  assert {
    condition     = data.aws_instance.current.instance_type == "t2.micro"
    error_message = "EC2 instance should be t2.micro type"
  }
}
```

### Viewing Continuous Validation Results

1. Navigate to your `tf-vault-qa-{your-initials}` workspace
2. Click **Health** → **Continuous validation**
3. View all resources, outputs, and data sources with custom assertions
4. Check whether assertions passed or failed
5. Review error messages for failed assertions

### Testing Continuous Validation

To test your continuous validation checks:

1. Add the check blocks above to your `main.tf` file
2. Commit and push the changes to trigger a new run
3. After the run completes, navigate to **Health** → **Continuous validation**
4. Observe how the checks validate your EC2 instances
5. Try modifying an instance in AWS console and trigger another health assessment to see validation failures

## Part 8: Best Practices

### Health Assessment Best Practices

1. **Enable Early**: Enable health assessments early in your infrastructure lifecycle
2. **Monitor Regularly**: Check health status regularly, especially after deployments
3. **Resolve Promptly**: Address drift and validation failures promptly
4. **Use Continuous Validation**: Implement check blocks for critical infrastructure components
5. **Document Expectations**: Document what health assessments should monitor

### Drift Prevention Strategies

1. **Access Controls**: Limit who can modify infrastructure directly
2. **Tagging Policies**: Use consistent tagging to track resource ownership
3. **Monitoring**: Set up alerts for health assessment failures
4. **Documentation**: Document expected infrastructure state

## Expected Results

By the end of this lab, you should have:
- Successfully enabled health assessments on your `tf-vault-qa-{your-initials}` workspace
- Triggered and observed on-demand health assessments for your EC2 instances
- Viewed health status indicators at organization and workspace levels
- Experienced drift detection and resolution workflows with your actual infrastructure
- Configured continuous validation checks for your EC2 instances
- Understood health assessment scheduling and timing
- Observed how health assessments integrate with your existing module testing workflow

## Troubleshooting

### Common Issues

1. **Health assessments not running**: Verify workspace requirements are met
2. **Drift not detected**: Ensure workspace has proper access to infrastructure
3. **Continuous validation failures**: Check assertion conditions and error messages
4. **Permission errors**: Verify administrator permissions for on-demand assessments

### Getting Help

- Check HCP Terraform documentation for detailed health assessment information
- Review workspace logs for assessment execution details
- Contact HashiCorp support for persistent issues

## Reflection

- How do health assessments improve your infrastructure management workflow compared to manual drift detection?
- What types of continuous validation checks would be most valuable for your EC2 instances and other AWS resources?
- How can you integrate health assessment results into your team's monitoring and alerting?
- How do health assessments complement the integration testing you set up in the previous lab?

## Key Concepts Covered

- **Health Assessments**: Automatic infrastructure monitoring and validation
- **Drift Detection**: Identifying differences between desired and actual infrastructure state
- **Continuous Validation**: Ongoing verification of custom infrastructure conditions
- **On-Demand Assessments**: Manual triggering of health evaluations
- **Drift Resolution**: Approaches to bringing infrastructure back in sync
- **Health Status Visibility**: Monitoring health across organization and workspaces

## Next Steps

After completing this lab, you can:
- Configure more complex continuous validation checks
- Set up health assessment alerts and notifications
- Integrate health assessment results with external monitoring tools
- Implement drift prevention strategies
- Explore advanced health assessment features and configurations
