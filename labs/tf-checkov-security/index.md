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
- Command line tools (PowerShell or Command Prompt)

**Windows Requirements:**
- Python 3.8+ installed and added to PATH
- Git for Windows (for pre-commit hooks)
- PowerShell or Command Prompt

## Install Python and Checkov

### 1. Install Python (if not already installed)

If Python is not installed on your Windows system:

1. Open an elevated PowerShell (Run as Administrator)
2. Type `python` and press Enter
3. This will open the Microsoft Store
4. Click "Install" to install Python from the Microsoft Store
5. After installation, close and reopen PowerShell

Verify Python installation:

```powershell
python --version
pip --version
```

### 2. Install Checkov

Install Checkov using pip:

```sh
pip install checkov
```

### 3. Verify Checkov Installation

Verify that Checkov is installed correctly:

**1: Add Python Scripts to PATH**

Add the Python Scripts directory to your PATH environment variable:

1. Open System Properties (Win + R, type `sysdm.cpl`)
2. Click Advanced > "Environment Variables"
3. Under "User variables", find "Path" and click "Edit"
4. Click "New" and add: `C:\Users\Admin\AppData\Local\Packages\PythonSoftwareFoundation.Python.3.13_qbz5n2kfra8p0\LocalCache\local-packages\Python313\Scripts`
5. Click "OK" on all dialogs
6. Close and reopen PowerShell

**2: Associate Python with .py files**
1. Open Command Prompt as Administrator (not PowerShell)
2. Run the following commands to fix Python file associations:

```cmd
assoc .py=Python.File
ftype Python.File="C:\Users\Admin\AppData\Local\Microsoft\WindowsApps\python.exe" "%1" %*
```

3. Then try running Checkov again:

```powershell
checkov --version
```

**Note for VS Code Users:** If Checkov works in a regular PowerShell window but not in VS Code's integrated terminal:

1. **Restart VS Code** completely (close and reopen)

## Scan Your Terraform Configuration

### 4. Navigate to Your Module Repository

```sh
cd terraform-aws-ec2-instance-tests-{your-initials}
```

### 5. Run Initial Security Scan

Run Checkov on your Terraform configuration:

```sh
checkov -d .\
```

**Note:** The `-d` flag requires a directory path. Use `.` for the current directory, or specify a full path like `checkov -d /path/to/terraform/files`.

**Expected Result:** Checkov will scan all Terraform files in the directory and report any security issues found.

### 6. Analyze the Results

Checkov will output results in the following format:

```
       _               _              
   ___| |__   ___  ___| | _______   __
  / __| '_ \ / _ \/ __| |/ / _ \ \ / /
 | (__| | | |  __/ (__|   <  __/\ V / 
  \___|_| |_|\___|\___|_|\_\___| \_/  
                                      
by bridgecrew.io | version: 2.3.xxx

terraform scan results:

Passed checks: 7, Failed checks: 11, Skipped checks: 0
```

## Configure Checkov

### 6. Create Checkov Configuration

Create a `.checkov.yaml` configuration file:

```sh
checkov --create-config .checkov.yaml
```

This will create a configuration file with your current settings.

### 7. Customize Configuration

Edit the `.checkov.yaml` file to customize your scanning. Add the following lines to the existing config:

```yaml
directory:
  - .
framework:
  - terraform
output: cli
quiet: false
soft-fail: false
skip-path:
  - \tests  # Skip tests directory
```

### 8. Re-run Checkov with Configuration

Run Checkov using your custom configuration file:

```sh
checkov --config-file .\.checkov.yaml
```

**Expected Result:** You should see fewer failures due to the skipped checks:

```
Passed checks: 3, Failed checks: 5, Skipped checks: 0
```

## Address Security Issues

### 9. Fix EC2 Instance Security Issues

Update your `main.tf` to address the security issues found by Checkov:

```hcl
resource "aws_instance" "app" {
  count = var.instance_count

  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  subnet_id              = var.subnet_ids[count.index % length(var.subnet_ids)]
  vpc_security_group_ids = var.security_group_ids

  # Add EBS optimization for better performance and security
  ebs_optimized = true

  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install httpd -y
    sudo systemctl enable httpd
    sudo systemctl start httpd
    echo "<html><body><div>Hello, world!</div></body></html>" > /var/www/html/index.html
    EOF

  tags = var.tags
}
```

### 10. Re-run Security Scan

After making the changes, run Checkov again:

```sh
checkov --config-file .\.checkov.yaml
```

**Expected Result:** The EC2 instance should now pass the EBS optimization check, reducing the number of failed checks.

### 11. Fix Instance Metadata Service Issue

Update your `main.tf` to address the IMDSv1 security issue:

```hcl
resource "aws_instance" "app" {
  count = var.instance_count

  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  ebs_optimized = true

  subnet_id              = var.subnet_ids[count.index % length(var.subnet_ids)]
  vpc_security_group_ids = var.security_group_ids

  # Disable IMDSv1 and enable IMDSv2 for better security
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install httpd -y
    sudo systemctl enable httpd
    sudo systemctl start httpd
    echo "<html><body><div>Hello, world!</div></body></html>" > /var/www/html/index.html
    EOF

  tags = var.tags
}
```

### 12. Re-run Security Scan Again

After making the IMDS changes, run Checkov again:

```sh
checkov --config-file .\.checkov.yaml
```

**Expected Result:** The EC2 instance should now pass both the EBS optimization and IMDSv2 checks, further reducing the number of failed checks.

### 13. Fix IAM Role Issue

Update your `main.tf` to address the IAM role security issue:

```hcl
# Create IAM role for EC2 instance
resource "aws_iam_role" "ec2_role" {
  name = "ec2-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Create IAM instance profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_instance" "app" {
  count = var.instance_count

  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  ebs_optimized = true

  subnet_id              = var.subnet_ids[count.index % length(var.subnet_ids)]
  vpc_security_group_ids = var.security_group_ids

  # Attach IAM role to EC2 instance
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install httpd -y
    sudo systemctl enable httpd
    sudo systemctl start httpd
    echo "<html><body><div>Hello, world!</div></body></html>" > /var/www/html/index.html
    EOF

  tags = var.tags
}
```

### 14. Re-run Security Scan Again

After making the IAM role changes, run Checkov again:

```sh
checkov --config-file .\.checkov.yaml
```

**Expected Result:** The EC2 instance should now pass the IAM role check, further reducing the number of failed checks.

## Advanced Checkov Features

### 15. Skip Specific Checks

You can skip specific checks using the configuration file instead of inline comments:

```yaml
# .checkov.yaml
directory:
  - .
framework:
  - terraform
output: cli
quiet: false
soft-fail: false
skip-path:
  - \tests  # Skip tests directory
skip-check:
  - CKV_AWS_8  # Skip EBS encryption check
  - CKV_AWS_126  # Skip EC2 Monitoring check
```

This approach is cleaner than inline comments and allows you to manage all skipped checks in one place.

### 16. Re-run Checkov with Updated Configuration

After updating the `.checkov.yaml` file with the new skip-check settings, run Checkov again:

```sh
checkov --config-file .\.checkov.yaml
```

**Expected Result:** You should see no see zero failed checks due to the skipped EBS encryption and EC2 monitoring checks.

```
Passed checks: 10, Failed checks: 0, Skipped checks: 0
```

### 17. Generate Detailed Reports

Generate a detailed report in JSON format:

```sh
checkov --config-file .\.checkov.yaml --output json --output-file-path checkov-report.json
```

### 18. Scan Specific Files

Scan only specific Terraform files:

```sh
checkov -f main.tf -f variables.tf
```

### 19. Use Different Output Formats

Try different output formats:

```sh
# JUnit XML format for CI/CD integration
checkov --config-file .\.checkov.yaml --output junitxml --output-file-path checkov-report.xml

# SARIF format for GitHub integration
checkov --config-file .\.checkov.yaml --output sarif --output-file-path checkov-report.sarif
```

### 20. Clean Up Generated Reports

After testing the different output formats, clean up the generated report files:

```sh
# Remove generated report files
Remove-Item checkov-report.json -ErrorAction SilentlyContinue
Remove-Item checkov-report.xml -ErrorAction SilentlyContinue
Remove-Item checkov-report.sarif -ErrorAction SilentlyContinue
```

### 21. Commit and Push Checkov Configuration

Add your Checkov configuration to version control:

```sh
# Add the Checkov configuration file
git add .

# Commit the configuration
git commit -m "Add Checkov security scanning configuration"

# Push to remote repository
git push
```

This ensures your security scanning configuration is saved and shared with your team.

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

### 3. **Comprehensive Coverage**
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