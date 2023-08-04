terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.11.0"
    }
  }
}

# Credentials come from environment variables.
provider "aws" {
  region = "us-east-1"
}

# Grab the latest Ubuntu 22.04 AMI for our region.
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical's AWS account ID.
}

# Deploy to default VPCs.
data "aws_vpc" "default" {
  default = true
}

# Retrieve the default subnets.
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name = "availability-zone"
    values = [
      "${data.aws_region.current.name}a",
      "${data.aws_region.current.name}b",
    ]
  }
}

# Retrieve the current AWS region.
data "aws_region" "current" {}

# An SSH key-pair to access the backing EC2 instances.
resource "aws_key_pair" "app" {
  key_name_prefix = "taskly"
  public_key      = var.ssh_public_key
}
