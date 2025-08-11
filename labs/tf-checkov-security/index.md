# Terraform Security Scanning with Checkov

## Overview

In this lab, you will use [Checkov](https://github.com/bridgecrewio/checkov) to perform static analysis and security scanning on your Terraform configurations. Checkov is a static analysis tool that scans infrastructure as code for security and compliance issues.

This lab builds upon the existing `learn-terraform-variables` repository and demonstrates how to integrate security scanning into your Terraform development workflow.

## Prerequisites

This lab builds upon the previous labs. You should have completed:
- `tf-unit-testing` - Unit testing with local mocking
- `tf-integration-testing` - Integration testing with HCP Terraform

You should be familiar with:
- Terraform configuration files
- Basic security concepts
- Command line tools

## Install Checkov

### 1. Install Checkov

Install Checkov using pip:

```sh
pip install checkov
```

Alternatively, you can install using Chocolatey (Windows):

```sh
choco install checkov
```

Or using Scoop (Windows):

```sh
scoop install checkov
```

### 2. Verify Installation

Verify that Checkov is installed correctly:

```sh
checkov --version
```

## Scan Your Terraform Configuration

### 3. Navigate to Your Repository

```sh
cd learn-terraform-variables
```

**Note for Windows Users:** If you're using PowerShell, you may need to use backslashes or forward slashes:

```powershell
cd .\learn-terraform-variables
# or
cd ./learn-terraform-variables
```

### 4. Run Initial Security Scan

Run Checkov on your Terraform configuration:

```sh
checkov -d .
```

**Expected Result:** Checkov will scan all Terraform files in the directory and report any security issues found.

### 5. Analyze the Results

Checkov will output results in the following format:

```
       _               _              
   ___| |__   ___  ___| | _______   __
  / __| '_ \ / _ \/ __| |/ / _ \ \ / /
 | (__| | | |  __/ (__|   <  __/\ V / 
  \___|_| |_|\___|\___|_|\_\___| \_/  
                                      
by bridgecrew.io | version: 2.3.xxx

terraform scan results:

Passed checks: 0, Failed checks: 3, Skipped checks: 0

Check: CKV_AWS_18: "Ensure the S3 bucket has access logging enabled"
	FAILED for resource: aws_s3_bucket.this
	File: /main.tf:1-5
	Guide: https://docs.bridgecrew.io/docs/s3_13-enable-logging

Check: CKV_AWS_21: "Ensure all data stored in the S3 bucket have versioning enabled"
	FAILED for resource: aws_s3_bucket.this
	File: /main.tf:1-5
	Guide: https://docs.bridgecrew.io/docs/s3_16-enable-versioning
```

## Configure Checkov

### 6. Create Checkov Configuration

Create a `.checkov.yaml` configuration file:

```sh
checkov --create-config .checkov.yaml
```

This will create a configuration file with your current settings.

### 7. Customize Configuration

Edit the `.checkov.yaml` file to customize your scanning:

```yaml
directory:
  - .
framework:
  - terraform
output: cli
quiet: false
soft-fail: false
skip-check:
  - CKV_AWS_18  # Skip S3 logging check for now
```

## Address Security Issues

### 8. Fix S3 Bucket Security Issues

Update your `main.tf` to address the security issues found by Checkov:

```hcl
# Add versioning to S3 bucket
resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Add logging configuration
resource "aws_s3_bucket_logging" "this" {
  bucket = aws_s3_bucket.this.id

  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "log/"
}

resource "aws_s3_bucket" "logs" {
  bucket = "${var.bucket_name}-logs"
}
```

### 9. Add Required Variables

Update your `variables.tf` to include the new bucket name variable:

```hcl
variable "bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
  default     = "my-terraform-bucket"
}
```

### 10. Re-run Security Scan

After making the changes, run Checkov again:

```sh
checkov -d .
```

**Expected Result:** Fewer security issues should be reported, and the S3 bucket should now pass the versioning and logging checks.

## Advanced Checkov Features

### 11. Skip Specific Checks

You can skip specific checks using inline comments in your Terraform files:

```hcl
resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
  #checkov:skip=CKV_AWS_18:This bucket doesn't need logging for this use case
}
```

### 12. Generate Detailed Reports

Generate a detailed report in JSON format:

```sh
checkov -d . --output json --output-file-path checkov-report.json
```

### 13. Scan Specific Files

Scan only specific Terraform files:

```sh
checkov -f main.tf -f variables.tf
```

### 14. Use Different Output Formats

Try different output formats:

```sh
# JUnit XML format for CI/CD integration
checkov -d . --output junitxml --output-file-path checkov-report.xml

# SARIF format for GitHub integration
checkov -d . --output sarif --output-file-path checkov-report.sarif
```

## Integration with Development Workflow

### 15. Pre-commit Hook

Create a pre-commit hook to run Checkov automatically:

**For Windows PowerShell:**
```powershell
# Create .pre-commit-config.yaml
@"
repos:
  - repo: https://github.com/bridgecrewio/checkov
    rev: master
    hooks:
      - id: checkov
        args: ['--directory', '.']
"@ | Out-File -FilePath .pre-commit-config.yaml -Encoding UTF8

# Install pre-commit
pip install pre-commit
pre-commit install
```

**For Windows Command Prompt:**
```cmd
# Create .pre-commit-config.yaml
echo repos: > .pre-commit-config.yaml
echo   - repo: https://github.com/bridgecrewio/checkov >> .pre-commit-config.yaml
echo     rev: master >> .pre-commit-config.yaml
echo     hooks: >> .pre-commit-config.yaml
echo       - id: checkov >> .pre-commit-config.yaml
echo         args: ['--directory', '.'] >> .pre-commit-config.yaml

# Install pre-commit
pip install pre-commit
pre-commit install
```

### 16. CI/CD Integration

Create a GitHub Actions workflow for automated scanning:

```yaml
# .github/workflows/checkov.yml
name: Checkov Security Scan

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Run Checkov
      uses: bridgecrewio/checkov-action@master
      with:
        directory: .
        framework: terraform
        output_format: cli
        soft_fail: false
```

## Expected Results

- Checkov successfully scans your Terraform configuration
- Security issues are identified and addressed
- Configuration is customized for your specific needs
- Integration with development workflow is established
- Automated scanning is set up for continuous security monitoring

## Benefits of Checkov Security Scanning

### 1. **Early Security Detection**
- Identifies security issues before deployment
- Prevents misconfigurations from reaching production
- Reduces security risks in infrastructure

### 2. **Compliance Validation**
- Ensures compliance with security best practices
- Validates against industry standards
- Provides audit trails for security reviews

### 3. **Automated Workflow Integration**
- Integrates with CI/CD pipelines
- Provides pre-commit hooks for local development
- Enables continuous security monitoring

### 4. **Comprehensive Coverage**
- Scans multiple cloud providers (AWS, Azure, GCP)
- Supports various IaC frameworks
- Covers security, compliance, and best practices

## Reflection

- **Reflection:** How does integrating security scanning into your development workflow improve the overall security posture of your infrastructure? What are the trade-offs between security and development speed?

## Key Concepts Covered

- **Static Analysis:** Understanding how Checkov analyzes Terraform code
- **Security Scanning:** Identifying and addressing security issues
- **Configuration Management:** Customizing Checkov for your needs
- **Workflow Integration:** Incorporating security scanning into development processes
- **Compliance:** Ensuring infrastructure meets security standards

## Next Steps

After completing this lab, you can:
- Explore additional Checkov checks and policies
- Integrate Checkov with your existing CI/CD pipeline
- Create custom policies for your organization
- Set up automated reporting and alerting
- Extend scanning to other infrastructure components

## Additional Resources

- [Checkov Documentation](https://www.checkov.io/)
- [Checkov GitHub Repository](https://github.com/bridgecrewio/checkov)
- [Terraform Security Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/security.html)
- [AWS Security Best Practices](https://aws.amazon.com/architecture/security-identity-compliance/) 