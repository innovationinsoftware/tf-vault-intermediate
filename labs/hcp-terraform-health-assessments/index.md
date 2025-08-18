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
2. Verify the workspace satisfies all assessment requirements. If not, run a new plan and apply in your workspace, and this error message should resolve.
3. Click **Start health assessment**

### Expected Results

After triggering the assessment, you should see:
- Health assessment status in the Health page
- Results showing your EC2 instances and their current state
- A message indicating "no drift detected" if your infrastructure matches your Terraform configuration
- Any drift detected between your Terraform configuration and actual AWS resources (if present)

## Part 5: Health Status Visibility

### Workspace-Level Health Status

1. Go to a specific workspace's overview page
2. Look for the **Health bar** on the right side of the page
3. The health bar summarizes the results of the last health assessment:
   - **Drift summary**: Shows total number of resources vs. drifted resources
   - **Checks summary**: Shows passed, failed, and unknown validation status counts

## Part 6: Viewing and Resolving Drift

### Viewing Drift Detection Results

1. Navigate to your `tf-vault-qa-{your-initials}` workspace
2. Click **Health** → **Drift**
3. View the drift detection results from the latest health assessment
4. You should see your EC2 instances and their current state
5. If drift is detected, HCP Terraform shows the necessary changes to bring infrastructure back in sync

### Creating Intentional Drift

To see drift detection in action, you can manually modify an EC2 instance in the AWS console:

1. Go to the AWS EC2 console at https://console.aws.amazon.com/ec2/
2. Login with your provided AWS credentials
3. Select **us-west-1** (or the region you selected in your Terraform configuration) from the region dropdown in the top-right corner
4. In the left navigation pane, click **Instances (running)**
5. Find one of your instances created by the `tf-vault-qa-{your-initials}` workspace 
4. Select the instance and click **Actions** → **Instance settings** → **Manage tags**
5. In the Tags section, find the "project" tag and change its value from "project-alpha" to "project-beta"
6. Click **Save** to apply the tag change
7. Return to HCP Terraform and navigate to your workspace's **Health** page
8. Click **Start health assessment** again
9. After the assessment completes, this should show any detected drift.
10. Observe how HCP Terraform shows the difference between your Terraform configuration (project-alpha) and the actual AWS resource (project-beta)

### Drift Resolution Approaches

When drift is detected, resolve it by reverting the change.

#### Remediate Drift
If you don't want to keep the drift's changes:
1. Queue a new plan in your workspace
2. Apply the changes to revert your real-world infrastructure to match your Terraform configuration

## Part 7: Continuous Validation

### Understanding Continuous Validation

Continuous validation regularly verifies whether your configuration's custom assertions continue to pass, validating your infrastructure. Examples include:
- Monitoring website status codes
- Validating API gateway certificates
- Checking resource availability

### Viewing Continuous Validation Results

1. Navigate to your `tf-vault-qa-{your-initials}` workspace
2. Click **Health** → **Continuous validation**
3. View all resources, outputs, and data sources with custom assertions
4. Check whether assertions passed or failed

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
