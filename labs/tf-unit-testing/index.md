# Terraform Unit Testing

## Overview

In this lab, you will add unit tests to your existing `learn-terraform-variables` Terraform configuration to validate configuration logic, variable validation, and conditional expressions without creating actual infrastructure. You'll test the existing VPC, security groups, load balancer, and EC2 instance modules to ensure they behave correctly under different input scenarios.

## Prerequisites

This lab builds upon the previous labs. You should have completed:
- `hcp-tf-setup` - HCP Terraform authentication and workspace setup
- `hcp-tf-modify` - Infrastructure modification and VCS workflow setup
- `hcp-tf-publish-module` - Module publishing and consumption

You should be working in your forked `learn-terraform-variables` repository with the existing infrastructure configuration.

## Understanding Your Current Configuration

Your existing configuration includes:
- **VPC Module**: Creates public and private subnets with NAT gateway
- **Security Groups**: Web server and load balancer security groups
- **Load Balancer**: Application Load Balancer with health checks
- **EC2 Instances**: Custom module creating web servers in private subnets
- **Variables**: `instance_count` and `instance_type` for EC2 instances

## Create Unit Tests for Your Configuration

### 1. Create a Test Directory

In your `learn-terraform-variables` repository, create a new directory for tests:

```sh
mkdir tests
cd tests
```

### 2. Test VPC Configuration Logic

Create a test file `vpc_tests.tftest.hcl` to validate your VPC module configuration:

```hcl
# tests/vpc_tests.tftest.hcl

variables {
  instance_count = 2
  instance_type  = "t2.micro"
}

run "test_vpc_subnet_configuration" {
  command = plan
  
  assert {
    condition     = length(module.vpc.private_subnets) == 2
    error_message = "VPC should have exactly 2 private subnets"
  }
  
  assert {
    condition     = length(module.vpc.public_subnets) == 2
    error_message = "VPC should have exactly 2 public subnets"
  }
  
  assert {
    condition     = module.vpc.enable_nat_gateway == true
    error_message = "NAT gateway should be enabled for private subnet internet access"
  }
}

run "test_vpc_cidr_ranges" {
  command = plan
  
  assert {
    condition     = module.vpc.vpc_cidr_block == "10.0.0.0/16"
    error_message = "VPC CIDR should be 10.0.0.0/16"
  }
  
  assert {
    condition     = module.vpc.private_subnets_cidr_blocks[0] == "10.0.101.0/24"
    error_message = "First private subnet should be 10.0.101.0/24"
  }
  
  assert {
    condition     = module.vpc.private_subnets_cidr_blocks[1] == "10.0.102.0/24"
    error_message = "Second private subnet should be 10.0.102.0/24"
  }
}
```

### 3. Test Security Group Configuration

Create a test file `security_group_tests.tftest.hcl` to validate security group logic:

```hcl
# tests/security_group_tests.tftest.hcl

variables {
  instance_count = 2
  instance_type  = "t2.micro"
}

run "test_app_security_group_configuration" {
  command = plan
  
  assert {
    condition     = module.app_security_group.name == "web-sg-project-alpha-dev"
    error_message = "App security group name should match expected pattern"
  }
  
  assert {
    condition     = module.app_security_group.vpc_id == module.vpc.vpc_id
    error_message = "App security group should be in the correct VPC"
  }
  
  assert {
    condition     = length(module.app_security_group.ingress_cidr_blocks) == 2
    error_message = "App security group should allow access from both public subnets"
  }
}

run "test_lb_security_group_configuration" {
  command = plan
  
  assert {
    condition     = module.lb_security_group.name == "lb-sg-project-alpha-dev"
    error_message = "Load balancer security group name should match expected pattern"
  }
  
  assert {
    condition     = module.lb_security_group.ingress_cidr_blocks[0] == "0.0.0.0/0"
    error_message = "Load balancer should allow access from anywhere (0.0.0.0/0)"
  }
}
```

### 4. Test Load Balancer Configuration

Create a test file `load_balancer_tests.tftest.hcl` to validate load balancer logic:

```hcl
# tests/load_balancer_tests.tftest.hcl

variables {
  instance_count = 2
  instance_type  = "t2.micro"
}

run "test_load_balancer_configuration" {
  command = plan
  
  assert {
    condition     = module.elb_http.internal == false
    error_message = "Load balancer should be external (internet-facing)"
  }
  
  assert {
    condition     = module.elb_http.subnets == module.vpc.public_subnets
    error_message = "Load balancer should be in public subnets"
  }
  
  assert {
    condition     = length(module.elb_http.instances) == 2
    error_message = "Load balancer should have 2 instances attached"
  }
}

run "test_load_balancer_health_check" {
  command = plan
  
  assert {
    condition     = module.elb_http.health_check[0].target == "HTTP:80/index.html"
    error_message = "Health check should target HTTP:80/index.html"
  }
  
  assert {
    condition     = module.elb_http.health_check[0].interval == 10
    error_message = "Health check interval should be 10 seconds"
  }
  
  assert {
    condition     = module.elb_http.health_check[0].healthy_threshold == 3
    error_message = "Healthy threshold should be 3"
  }
}
```

### 5. Test EC2 Instance Module

Create a test file `ec2_instance_tests.tftest.hcl` to validate your custom EC2 instance module:

```hcl
# tests/ec2_instance_tests.tftest.hcl

variables {
  instance_count = 2
  instance_type  = "t2.micro"
}

run "test_ec2_instance_count" {
  command = plan
  
  assert {
    condition     = length(module.ec2_instances.instance_ids) == 2
    error_message = "Should create exactly 2 EC2 instances"
  }
}

run "test_ec2_instance_placement" {
  command = plan
  
  assert {
    condition     = length(module.ec2_instances.subnet_ids) == 2
    error_message = "EC2 instances should be distributed across 2 subnets"
  }
  
  assert {
    condition     = module.ec2_instances.security_group_ids[0] == module.app_security_group.this_security_group_id
    error_message = "EC2 instances should use the app security group"
  }
}

run "test_ec2_instance_tags" {
  command = plan
  
  assert {
    condition     = module.ec2_instances.tags.project == "project-alpha"
    error_message = "EC2 instances should have project-alpha tag"
  }
  
  assert {
    condition     = module.ec2_instances.tags.environment == "dev"
    error_message = "EC2 instances should have dev environment tag"
  }
}
```

### 6. Test Variable Validation

Create a test file `variable_validation_tests.tftest.hcl` to test variable constraints:

```hcl
# tests/variable_validation_tests.tftest.hcl

run "test_valid_instance_count" {
  command = plan
  
  variables {
    instance_count = 3
    instance_type  = "t2.small"
  }
  
  # This should pass - valid instance count and type
}

run "test_instance_count_distribution" {
  command = plan
  
  variables {
    instance_count = 4
    instance_type  = "t2.micro"
  }
  
  # Test that instances are distributed across available subnets
  assert {
    condition     = length(module.ec2_instances.subnet_ids) == 2
    error_message = "Should have 2 subnets available for instance distribution"
  }
}

run "test_load_balancer_instance_attachment" {
  command = plan
  
  variables {
    instance_count = 1
    instance_type  = "t2.micro"
  }
  
  assert {
    condition     = length(module.elb_http.instances) == 1
    error_message = "Load balancer should attach to exactly 1 instance"
  }
}
```

## Run Your Unit Tests

1. From your `learn-terraform-variables` directory, run the tests:

```sh
terraform test tests/
```

This will execute all your test files and validate that your configuration logic works correctly for different input scenarios.

## Expected Results

- All unit tests pass, validating your existing infrastructure configuration
- VPC subnet configuration is correct (2 public, 2 private)
- Security groups are properly configured for web servers and load balancer
- Load balancer health checks and instance attachment work correctly
- EC2 instances are properly distributed across subnets
- Variable changes affect infrastructure as expected

## Reflection & Challenge

- **Reflection:** How do unit tests complement the infrastructure testing you've done in previous labs? What are the trade-offs between testing speed and coverage?
- **Challenge:**
  - Add a new variable `environment` with validation that only allows specific values (dev, staging, prod)
  - Create tests for different environment scenarios
  - Test edge cases like minimum/maximum instance counts
  - Add validation to ensure instance count doesn't exceed available subnets

## Key Concepts Covered

- **Unit Testing vs Integration Testing:** Understanding when to use each approach
- **Test File Structure:** Using `.tftest.hcl` files with `run` blocks and `assert` statements
- **Module Testing:** Validating that your custom modules behave correctly
- **Infrastructure Logic Testing:** Testing VPC, security group, and load balancer configuration
- **Test Organization:** Structuring tests into logical groups for maintainability

## Next Steps

After completing this lab, you'll be ready to create integration tests that validate actual infrastructure creation and resource properties. Integration tests will build upon these unit testing concepts while adding real infrastructure validation. 