# Terraform Integration Testing with HCP Terraform

## Overview

In this lab, you will create integration tests for your existing `learn-terraform-variables` Terraform configuration that will run in your HCP Terraform workspace. Unlike unit tests that validate configuration logic without creating infrastructure, integration tests create real AWS resources and validate their actual properties, ensuring your infrastructure behaves correctly in the cloud environment.

## Prerequisites

This lab builds upon the previous labs. You should have completed:
- `hcp-tf-setup` - HCP Terraform authentication and workspace setup
- `hcp-tf-modify` - Infrastructure modification and VCS workflow setup
- `hcp-tf-publish-module` - Module publishing and consumption
- `tf-unit-testing` - Unit testing with `command = plan`

You should be working in your forked `learn-terraform-variables` repository with VCS integration enabled in your HCP Terraform workspace.

## Understanding Integration Testing in HCP Terraform

### How Integration Tests Work in HCP Terraform

Integration tests in HCP Terraform work differently from local testing:

| Aspect | Local Testing | HCP Terraform Testing |
|--------|---------------|----------------------|
| **Execution Environment** | Your local machine | HCP Terraform cloud workspace |
| **Trigger** | `terraform test` command | Git push to repository |
| **Infrastructure** | Your local AWS account | HCP Terraform's AWS account |
| **Cost** | You pay for resources | HCP Terraform pays for resources |
| **Cleanup** | Automatic after test | Automatic after test |
| **Logs** | Local terminal | HCP Terraform UI |

### Integration Testing vs Unit Testing

| Aspect | Unit Testing | Integration Testing |
|--------|--------------|-------------------|
| **Command** | `command = plan` | `command = apply` (default) |
| **Infrastructure** | No resources created | Real AWS resources created |
| **Speed** | Seconds | Minutes (10-15 minutes) |
| **Cost** | Free | HCP Terraform covers costs |
| **Validation** | Configuration logic | Actual resource properties |
| **Use Case** | Fast feedback during development | Final validation before production |

## Create Integration Tests for Your Infrastructure

### 1. Create Integration Test Directory

In your `learn-terraform-variables` repository, create a new directory for integration tests:

```sh
mkdir integration-tests
cd integration-tests
```

### 2. Test VPC Resource Creation

Create a test file `vpc_integration_tests.tftest.hcl` to validate actual VPC creation:

```hcl
# integration-tests/vpc_integration_tests.tftest.hcl

variables {
  instance_count = 2
  instance_type  = "t2.micro"
}

run "test_vpc_creation" {
  command = apply
  
  assert {
    condition     = module.vpc.vpc_id != ""
    error_message = "VPC should be created with a valid ID"
  }
  
  assert {
    condition     = can(regex("^vpc-", module.vpc.vpc_id))
    error_message = "VPC ID should start with 'vpc-'"
  }
  
  assert {
    condition     = module.vpc.vpc_cidr_block == "10.0.0.0/16"
    error_message = "VPC should have the correct CIDR block"
  }
}

run "test_subnet_creation" {
  command = apply
  
  assert {
    condition     = length(module.vpc.private_subnets) == 2
    error_message = "Should create exactly 2 private subnets"
  }
  
  assert {
    condition     = length(module.vpc.public_subnets) == 2
    error_message = "Should create exactly 2 public subnets"
  }
  
  # Test that subnets are actually created in AWS
  assert {
    condition     = alltrue([for subnet in module.vpc.private_subnets : can(regex("^subnet-", subnet))])
    error_message = "All private subnets should have valid subnet IDs"
  }
  
  assert {
    condition     = alltrue([for subnet in module.vpc.public_subnets : can(regex("^subnet-", subnet))])
    error_message = "All public subnets should have valid subnet IDs"
  }
}

run "test_nat_gateway_creation" {
  command = apply
  
  assert {
    condition     = module.vpc.nat_gateway_ids != null
    error_message = "NAT gateway should be created"
  }
  
  assert {
    condition     = length(module.vpc.nat_gateway_ids) == 2
    error_message = "Should create NAT gateway for each availability zone"
  }
}
```

### 3. Test Security Group Creation

Create a test file `security_group_integration_tests.tftest.hcl` to validate security group creation:

```hcl
# integration-tests/security_group_integration_tests.tftest.hcl

variables {
  instance_count = 2
  instance_type  = "t2.micro"
}

run "test_app_security_group_creation" {
  command = apply
  
  assert {
    condition     = module.app_security_group.this_security_group_id != ""
    error_message = "App security group should be created with a valid ID"
  }
  
  assert {
    condition     = can(regex("^sg-", module.app_security_group.this_security_group_id))
    error_message = "Security group ID should start with 'sg-'"
  }
  
  assert {
    condition     = module.app_security_group.vpc_id == module.vpc.vpc_id
    error_message = "Security group should be created in the correct VPC"
  }
  
  assert {
    condition     = module.app_security_group.name == "web-sg-project-alpha-development"
    error_message = "Security group should have the correct name"
  }
}

run "test_lb_security_group_creation" {
  command = apply
  
  assert {
    condition     = module.lb_security_group.this_security_group_id != ""
    error_message = "Load balancer security group should be created with a valid ID"
  }
  
  assert {
    condition     = can(regex("^sg-", module.lb_security_group.this_security_group_id))
    error_message = "Load balancer security group ID should start with 'sg-'"
  }
  
  assert {
    condition     = module.lb_security_group.vpc_id == module.vpc.vpc_id
    error_message = "Load balancer security group should be created in the correct VPC"
  }
}
```

### 4. Test EC2 Instance Creation

Create a test file `ec2_integration_tests.tftest.hcl` to validate EC2 instance creation:

```hcl
# integration-tests/ec2_integration_tests.tftest.hcl

variables {
  instance_count = 2
  instance_type  = "t2.micro"
}

run "test_ec2_instance_creation" {
  command = apply
  
  assert {
    condition     = length(module.ec2_instances.instance_ids) == 2
    error_message = "Should create exactly 2 EC2 instances"
  }
  
  assert {
    condition     = alltrue([for id in module.ec2_instances.instance_ids : can(regex("^i-", id))])
    error_message = "All EC2 instances should have valid instance IDs"
  }
  
  assert {
    condition     = alltrue([for id in module.ec2_instances.instance_ids : id != ""])
    error_message = "All EC2 instance IDs should be non-empty"
  }
}

run "test_ec2_instance_placement" {
  command = apply
  
  assert {
    condition     = length(module.ec2_instances.subnet_ids) == 2
    error_message = "EC2 instances should be distributed across 2 subnets"
  }
  
  assert {
    condition     = alltrue([for subnet in module.ec2_instances.subnet_ids : can(regex("^subnet-", subnet))])
    error_message = "All EC2 instances should be in valid subnets"
  }
  
  assert {
    condition     = module.ec2_instances.security_group_ids[0] == module.app_security_group.this_security_group_id
    error_message = "EC2 instances should use the app security group"
  }
}

run "test_ec2_instance_tags" {
  command = apply
  
  assert {
    condition     = module.ec2_instances.tags.project == "project-alpha"
    error_message = "EC2 instances should have project-alpha tag"
  }
  
  assert {
    condition     = module.ec2_instances.tags.environment == "development"
    error_message = "EC2 instances should have development environment tag"
  }
}
```

### 5. Test Load Balancer Creation

Create a test file `load_balancer_integration_tests.tftest.hcl` to validate load balancer creation:

```hcl
# integration-tests/load_balancer_integration_tests.tftest.hcl

variables {
  instance_count = 2
  instance_type  = "t2.micro"
}

run "test_load_balancer_creation" {
  command = apply
  
  assert {
    condition     = module.elb_http.this_elb_id != ""
    error_message = "Load balancer should be created with a valid ID"
  }
  
  assert {
    condition     = can(regex("^lb-", module.elb_http.this_elb_id))
    error_message = "Load balancer ID should start with 'lb-'"
  }
  
  assert {
    condition     = module.elb_http.internal == false
    error_message = "Load balancer should be external (internet-facing)"
  }
  
  assert {
    condition     = length(module.elb_http.subnets) == 2
    error_message = "Load balancer should be in both public subnets"
  }
}

run "test_load_balancer_instance_attachment" {
  command = apply
  
  assert {
    condition     = length(module.elb_http.instances) == 2
    error_message = "Load balancer should have 2 instances attached"
  }
  
  assert {
    condition     = alltrue([for instance in module.elb_http.instances : can(regex("^i-", instance))])
    error_message = "All attached instances should have valid instance IDs"
  }
  
  # Verify instances are the same as created by our EC2 module
  assert {
    condition     = length(setintersection(module.elb_http.instances, module.ec2_instances.instance_ids)) == 2
    error_message = "Load balancer should be attached to our EC2 instances"
  }
}

run "test_load_balancer_health_check" {
  command = apply
  
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
  
  assert {
    condition     = module.elb_http.health_check[0].unhealthy_threshold == 10
    error_message = "Unhealthy threshold should be 10"
  }
}
```

### 6. Test Infrastructure Connectivity

Create a test file `connectivity_integration_tests.tftest.hcl` to validate resource relationships:

```hcl
# integration-tests/connectivity_integration_tests.tftest.hcl

variables {
  instance_count = 2
  instance_type  = "t2.micro"
}

run "test_vpc_security_group_relationship" {
  command = apply
  
  assert {
    condition     = module.app_security_group.vpc_id == module.vpc.vpc_id
    error_message = "App security group should be in the correct VPC"
  }
  
  assert {
    condition     = module.lb_security_group.vpc_id == module.vpc.vpc_id
    error_message = "Load balancer security group should be in the correct VPC"
  }
}

run "test_subnet_instance_relationship" {
  command = apply
  
  # Verify instances are in private subnets
  assert {
    condition     = alltrue([for subnet in module.ec2_instances.subnet_ids : contains(module.vpc.private_subnets, subnet)])
    error_message = "EC2 instances should be in private subnets"
  }
  
  # Verify load balancer is in public subnets
  assert {
    condition     = alltrue([for subnet in module.elb_http.subnets : contains(module.vpc.public_subnets, subnet)])
    error_message = "Load balancer should be in public subnets"
  }
}

run "test_security_group_instance_relationship" {
  command = apply
  
  assert {
    condition     = module.ec2_instances.security_group_ids[0] == module.app_security_group.this_security_group_id
    error_message = "EC2 instances should use the app security group"
  }
  
  assert {
    condition     = module.elb_http.security_groups[0] == module.lb_security_group.this_security_group_id
    error_message = "Load balancer should use the load balancer security group"
  }
}
```

## Trigger Integration Tests in HCP Terraform

### 1. Commit and Push Your Integration Tests

Add your integration tests to your repository:

```sh
git add integration-tests/
git commit -m "Add integration tests for infrastructure validation"
git push origin main
```

### 2. Monitor Test Execution in HCP Terraform

1. Go to your HCP Terraform workspace
2. Navigate to the **Runs** page
3. You should see a new run triggered by your git push
4. Click on the run to view details
5. The run will execute your integration tests and create real infrastructure

### 3. Review Test Results

In the HCP Terraform UI, you can:
- View the plan output showing what resources will be created
- See the apply output showing actual resource creation
- Review test results and any failures
- Monitor resource creation in real-time

## Expected Results

- Integration tests run in your HCP Terraform workspace
- Real AWS resources are created and validated
- Tests validate actual infrastructure properties and relationships
- Resources are automatically destroyed after testing
- All test results are visible in the HCP Terraform UI

## Benefits of HCP Terraform Integration Testing

### 1. **No Local AWS Costs**
- HCP Terraform covers the cost of test resources
- No need to configure local AWS credentials for testing
- No risk of orphaned resources in your personal AWS account

### 2. **Consistent Environment**
- Tests run in the same environment as your production infrastructure
- No differences between local and cloud environments
- Consistent AWS provider versions and configurations

### 3. **Team Collaboration**
- Test results are visible to your team in HCP Terraform
- Integration tests can be part of your CI/CD pipeline
- Test history is preserved and auditable

### 4. **Automated Workflow**
- Tests trigger automatically on git pushes
- No manual test execution required
- Integration with your existing VCS workflow

## Reflection & Challenge

- **Reflection:** How does running integration tests in HCP Terraform improve the testing experience compared to local testing? What are the trade-offs?
- **Challenge:**
  - Create a test that validates the web server is actually serving content (you may need to use data sources)
  - Test load balancer health check behavior by creating instances that fail health checks
  - Add tests for different instance types and verify they work correctly
  - Test the NAT gateway functionality by verifying instances can access the internet

## Key Concepts Covered

- **HCP Terraform Integration Testing:** Running tests in the cloud workspace
- **VCS-Driven Testing:** Triggering tests through git pushes
- **Real Infrastructure Validation:** Testing actual resource properties and relationships
- **Automated Test Execution:** Integration with existing VCS workflow
- **Cost-Free Testing:** HCP Terraform covers test resource costs

## Next Steps

After completing this lab, you'll have a comprehensive testing strategy:
- **Unit tests** for fast configuration validation during development
- **Integration tests** for final validation of real infrastructure behavior
- **HCP Terraform integration** for automated, cost-free testing

This approach ensures your infrastructure is reliable while leveraging the benefits of HCP Terraform's cloud-based testing environment. 