terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "eu-west-1"
}


module "aws_vpc" {
  source                          = "../"
  create_vpc                      = true
  vpc_cidr_block                  = "10.1.0.0/16"
  public_subnets                  = ["10.1.1.0/24", "10.1.2.0/24"]
  azs                             = ["eu-west-1a", "eu-west-1b"]
  private_subnets                 = ["10.1.3.0/24", "10.1.4.0/24"]
  enable_ipv6                     = true
  assign_ipv6_address_on_creation = true
  manage_default_security_group   = true
  ingress_security_group_rules    = var.default_ingress_sg_rules
  egress_security_group_rules     = var.default_egress_sg_rules
  manage_default_network_acl      = true
  default_ingress_nacl_rules      = var.default_ingress_nacl_rules
  default_egress_nacl_rules       = var.default_egress_nacl_rules
  public_subnet_ipv6_prefixes     = [0, 1]
  private_subnet_ipv6_prefixes    = [2, 3]
  enable_public_route             = true
  enable_public_ip                = [true, true]
  enable_nat                      = true
  nat_gateway_for_each_subnet     = true
  public_subnet_tags = {
    Name = "Public server"
  }
  private_subnet_tags = {
    Name = "private server"
  }
}


