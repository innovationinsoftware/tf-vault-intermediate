terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  environment_id = var.environment_name
  common_tags = {
    Environment = var.environment_name
    Type        = "qa"
    Owner       = "qa-team"
    AutoDelete  = "true"
  }
}

# Simple EC2 instance for QA testing
resource "aws_instance" "qa_server" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  tags = merge(local.common_tags, {
    Name = "${local.environment_id}-qa-server"
  })
}

# Data source for Amazon Linux AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Outputs
output "instance_id" {
  value = aws_instance.qa_server.id
}

output "environment_id" {
  value = local.environment_id
}
