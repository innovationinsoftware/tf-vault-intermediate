# Terraform Integration Testing with HCP Terraform

## Overview

In this lab, you will create a new repository for your EC2 instance module and set up integration testing in HCP Terraform. Following the [Terraform testing tutorial](https://developer.hashicorp.com/terraform/tutorials/configuration-language/test), you'll move your existing module to a new repository, publish it to the HCP Terraform private module registry, and run tests remotely in HCP Terraform.

## Prerequisites

This lab builds upon the previous labs. You should have completed:
- `hcp-tf-setup` - HCP Terraform authentication and workspace setup
- `hcp-tf-modify` - Infrastructure modification and VCS workflow setup
- `hcp-tf-publish-module` - Module publishing and consumption
- `tf-unit-testing` - Unit testing with local mocking

You should be familiar with:
- HCP Terraform private module registry
- GitHub repository management
- Terraform module structure

## Create New Repository

### 1. Create GitHub Repository

Navigate to GitHub and create a new repository named `terraform-aws-ec2-instance-tests-{your-initials}`. The repository name must follow the format `terraform-<PROVIDER>-<NAME>` for HCP Terraform module registry compatibility.

### 2. Clone the Repository

```sh
git clone https://github.com/YOUR_USERNAME/terraform-aws-ec2-instance-tests-{your-initials}
cd terraform-aws-ec2-instance-tests-{your-initials}
```

## Move Module and Tests

### 3. Copy EC2 Instance Module Files

Copy your existing EC2 instance module files from `learn-terraform-variables/modules/aws-instance` to the root of the new repository:

```sh
# Copy the module files to root directory
cp ../learn-terraform-variables/modules/aws-instance/* ./
```

The module files (main.tf, variables.tf, outputs.tf) should be in the root directory of the repository, not in a subdirectory. This is the standard structure for modules published to the HCP Terraform registry.

### 4. Update Module Files

The module files you copied should already contain the necessary configuration. If needed, update them to ensure they work as a standalone module:

- `main.tf` - Contains the EC2 instance resources
- `variables.tf` - Contains the module variables
- `outputs.tf` - Contains the module outputs

### 5. Create README

Create a `README.md` file:

```markdown
# terraform-aws-ec2-instance-tests-{your-initials}

A Terraform module for creating EC2 instances with integration tests.

## Usage

```hcl
module "ec2_instances" {
  source = "app.terraform.io/YOUR_ORG/ec2-instance-tests-{your-initials}/aws"
  
  instance_count = 2
  instance_type  = "t2.micro"
}
```

## Requirements

- Terraform >= 1.0
- AWS Provider >= 3.76
```

## Create Integration Tests

### 6. Create Test Directory Structure

```sh
mkdir -p tests/setup
```

### 7. Create Setup Helper Module

Create `tests/setup/main.tf` to provide test infrastructure:

```hcl
# tests/setup/main.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.76"
    }
  }
}

# Create a VPC for testing
resource "aws_vpc" "test_vpc" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "test-vpc"
  }
}

# Create a subnet for testing
resource "aws_subnet" "test_subnet" {
  vpc_id            = aws_vpc.test_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-1a"
  
  tags = {
    Name = "test-subnet"
  }
}

# Create a security group for testing
resource "aws_security_group" "test_sg" {
  name_prefix = "test-sg"
  vpc_id      = aws_vpc.test_vpc.id
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "vpc_id" {
  value = aws_vpc.test_vpc.id
}

output "subnet_id" {
  value = aws_subnet.test_subnet.id
}

output "security_group_id" {
  value = aws_security_group.test_sg.id
}
```

### 8. Create Integration Test

Create `tests/integration.tftest.hcl`:

```hcl
# tests/integration.tftest.hcl

run "setup_infrastructure" {
  module {
    source = "./tests/setup"
  }
}

run "test_ec2_instance_creation" {
  command = apply
  
  variables {
    instance_count = 2
    instance_type  = "t2.micro"
    security_group_ids = [run.setup_infrastructure.security_group_id]
    subnet_ids = [run.setup_infrastructure.subnet_id]
  }
  
  # Test that instances are created
  assert {
    condition     = length(aws_instance.app[*].id) == 2
    error_message = "Should create exactly 2 EC2 instances"
  }
  
  # Test that instance IDs are valid
  assert {
    condition     = alltrue([for id in aws_instance.app[*].id : can(regex("^i-", id))])
    error_message = "All EC2 instances should have valid instance IDs"
  }
}

run "test_instance_count_variable" {
  command = apply
  
  variables {
    instance_count = 3
    instance_type  = "t2.small"
    security_group_ids = [run.setup_infrastructure.security_group_id]
    subnet_ids = [run.setup_infrastructure.subnet_id]
  }
  
  # Test that variable changes affect instance count
  assert {
    condition     = length(aws_instance.app[*].id) == 3
    error_message = "Should create exactly 3 EC2 instances when instance_count = 3"
  }
}
```

## Publish to HCP Terraform

### 11. Commit and Push

```sh
git add .
git commit -m "Initial commit with EC2 instance module and integration tests"
git push origin main
```

### 12. Create Version Tag

```sh
git tag v1.0.0
git push origin v1.0.0
```

### 13. Publish to HCP Terraform

1. Go to your HCP Terraform organization
2. Navigate to **Registry** → **Modules**
3. Click **Publish Module**
4. Select your GitHub repository
5. Choose **Branch-based** publishing
6. Select the 'main' branch and the 1.0.0 version
6. Select 'Enable Testing for Module'
7. Click **Publish Module**

## Run Tests in HCP Terraform

### 14. Configure Module Tests

1. In your HCP Terraform module page, go to **Testing**
2. Click **Configure tests**
3. Add the same AWS credentials you configured in the `hcp-tf-setup` lab:
   - `AWS_ACCESS_KEY_ID` (sensitive)
   - `AWS_SECRET_ACCESS_KEY` (sensitive)
   - `AWS_REGION` (set to your preferred region, e.g., `us-west-1`)
   
### 15. Trigger Tests with Code Changes

Instead of running tests from the CLI, you can trigger tests automatically by making changes to your repository:

1. Make a small change to your `README.md` file (add a comment or update description)
2. Commit and push the change:

```sh
git add README.md
git commit -m "Trigger integration tests"
git push origin main
```

**Expected Result: FAILURE** - The tests should fail with the following error:

```
Error: error creating EC2 Subnet: InvalidParameterValue: Value (us-west-1a) for parameter availabilityZone is invalid. Subnets can currently only be created in the following availability zones: us-west-1b, us-west-1c. status code: 400
with aws_subnet.test_subnet
on tests/setup/main.tf line 20, in resource "aws_subnet" "test_subnet":
```

### 16. Fix the Availability Zone Issue

The test is failing because `us-west-1a` is not available in your AWS region. Fix this by updating the availability zone in `tests/setup/main.tf`:

```hcl
resource "aws_subnet" "test_subnet" {
  vpc_id            = aws_vpc.test_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-1b"  # Changed from us-west-1a
  
  tags = {
    Name = "test-subnet"
  }
}
```

3. Commit and push the fix:

```sh
git add tests/setup/main.tf
git commit -m "Fix availability zone for subnet"
git push origin main
```

**Expected Result: SUCCESS** - The tests should now pass with the correct availability zone.

## Expected Results

- Module is successfully published to HCP Terraform private registry
- Integration tests run in HCP Terraform environment
- Tests validate actual EC2 instance creation
- Tests verify variable changes affect infrastructure
- All tests pass, confirming module functionality

## Benefits of HCP Terraform Integration Testing

### 1. **Real Infrastructure Validation**
- Tests create actual AWS resources
- Validates real provider behavior
- Tests actual resource properties and relationships

### 2. **Secure Testing Environment**
- HCP Terraform manages credentials
- No local AWS credentials needed
- Centralized security management

### 3. **Automated Workflow**
- Tests run automatically on module publish
- Integration with VCS workflow
- Consistent testing environment

### 4. **Team Collaboration**
- Test results visible to team
- Test history preserved
- Integration with CI/CD pipelines

## Reflection

- **Reflection:** How does running integration tests in HCP Terraform improve the testing experience compared to local unit tests? What are the trade-offs between testing speed, cost, and coverage?

## Key Concepts Covered

- **Module Repository Structure:** Creating standalone module repositories
- **HCP Terraform Module Registry:** Publishing and versioning modules
- **Integration Testing:** Testing with real infrastructure creation
- **Helper Modules:** Using setup modules for test infrastructure
- **Remote Testing:** Running tests in HCP Terraform environment

## Next Steps

After completing this lab, you can:
- Add more complex test scenarios
- Test different instance types and configurations
- Add validation for security groups and networking
- Integrate with CI/CD pipelines for automated testing
- Create additional helper modules for different test scenarios
