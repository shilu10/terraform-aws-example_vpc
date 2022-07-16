variable "public_subnet_tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags for the public subnets"
}

variable "public_subnets" {
  type        = list(string)
  default     = []
  description = "Takes list of subnet with their subnet mask"
}

variable "private_subnet_tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags for the private subnets"
}

variable "private_subnets" {
  type        = list(string)
  default     = []
  description = "Takes list of subnet with their subnet mask"
}

variable "vpc_id" {
  type        = string
  default     = ""
  description = "Id of your vpc"
}

variable "azs" {
  type        = list(string)
  default     = []
  description = "az's available in the vpc"
}

variable "vpc_cidr_block" {
  type        = string
  default     = ""
  description = "Vpc cidr block"
}

variable "enable_public_route" {
  type        = bool
  default     = false
  description = "If true, enables the public routing, false there won't be a public internet access"
}

variable "enable_public_ip" {
  type        = list(bool)
  default     = []
  description = "To provide a public ip address for an subnet while creation"
}

variable "enable_nat" {
  type        = string
  default     = false
  description = "This will just enables the nat gateway for all private subnets"
}

variable "assign_private_ipv6" {
  type        = list(string)
  default     = []
  description = "This will create an private ipv6 add for an subnet, while it is provisioning"
}

variable "assign_public_ipv6" {
  type        = list(string)
  default     = []
  description = "This will create an public ipv6 add for an subnet, while it is provisioning"
}

variable "enable_ipv6" {
  type        = string
  default     = false
  description = "This will enables an ipv6 address"
}

variable "public_subnet_ipv6_prefixes" {
  description = "Assigns IPv6 public subnet id based on the Amazon provided /56 prefix base 10 integer (0-256). Must be of equal length to the corresponding IPv4 subnet list"
  type        = list(string)
  default     = []
}

variable "private_subnet_ipv6_prefixes" {
  description = "Assigns IPv6 public subnet id based on the Amazon provided /56 prefix base 10 integer (0-256). Must be of equal length to the corresponding IPv4 subnet list"
  type        = list(string)
  default     = []
}

variable "assign_ipv6_address_on_creation" {
  type        = bool
  default     = false
  description = "This will create an ipv6 address for each subnet, while it is provisioning"
}

variable "manage_default_security_group" {
  type        = bool
  default     = false
  description = "This will allows you to provide a default security group rules for you VPC"
}

variable "create_vpc" {
  type        = bool
  default     = false
  description = "This only enables an vpc, it is needed, bcoz most of the resources rely on it."
}

variable "ingress_security_group_rules" {
  type = list(map(string))
  default = [{

  }]
  description = "Inbound security Group rules"
}

variable "egress_security_group_rules" {
  type = list(map(string))
  default = [{

  }]
  description = "Outbound security Group rules"
}

variable "single_nat_gateway" {
  type        = bool
  default     = false
  description = "Allows user to have a single nat gateway for all of their subnets"
}

variable "nat_gateway_for_each_subnet" {
  type        = bool
  default     = false
  description = "Allows users to have one gateway for eahc subnet their created"
}

variable "manage_default_network_acl" {
  type        = bool
  default     = false
  description = "To manage a default network access control list for all of the subnets"
}

variable "default_ingress_nacl_rules" {
  type = list(map(string))
  default = [
    {
      rule_no    = 100
      action     = "allow"
      from_port  = 0
      to_port    = 0
      protocol   = "-1"
      cidr_block = "0.0.0.0/0"
    },
    {
      rule_no         = 101
      action          = "allow"
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      ipv6_cidr_block = "::/0"
    },
  ]
  description = "this is used to maintain a default network access list rules"
}

variable "default_egress_nacl_rules" {
  type = list(map(string))
  default = [
    {
      rule_no    = 100
      action     = "allow"
      from_port  = 0
      to_port    = 0
      protocol   = "-1"
      cidr_block = "0.0.0.0/0"
    },
    {
      rule_no         = 101
      action          = "allow"
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      ipv6_cidr_block = "::/0"
    },
  ]
  description = "this is used to maintain a default network access list rules"
}

variable "create_inbound_sg_rules" {
  type        = list(map(string))
  default     = [{}]
  description = "This is used to create a new ingress security group rules, which is non-default."
}

variable "create_outbound_sg_rules" {
  type        = list(map(string))
  default     = [{}]
  description = "This is used to create a new egress security group rules, which is non-default."
}

variable "public_dedicated_network_acl" {
  type        = bool
  default     = false
  description = "This allow you to create a single acl for all the public subnets"
}

variable "private_dedicated_network_acl" {
  type        = bool
  default     = false
  description = "This allow you to create a single acl for all the private subnets"
}

variable "public_inbound_acl_rules" {
  type = list(map(string))
  default = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
  ]
  description = "this allow you to write a inbound acl rule for all the public subnets"
}

variable "public_outbound_acl_rules" {
  type = list(map(string))
  default = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
  ]
  description = "this allow you to write a outbound acl rule for all the public subnets"
}

variable "private_inbound_acl_rules" {
  type = list(map(string))
  default = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
  ]
  description = "this allow you to write a inbound acl rule for all the private subnets "
}

variable "private_outbound_acl_rules" {
  type = list(map(string))
  default = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
  ]
  description = "this allow you to write a outbound acl rule for all the private subnets"
}

variable "internet_gateway_tags" {
  type        = map(string)
  default     = {}
  description = "Tags for an internet gateway"
}

variable "private_route_table_tags" {
  type        = map(string)
  default     = {}
  description = "Tags for an Private Route table"
}

variable "public_route_table_tags" {
  type        = map(string)
  default     = {}
  description = "Tags for an Public Route table"
}

variable "nat_gateway_tags" {
  type        = map(string)
  default     = {}
  description = "Tags for an NAT Gateway"
}

variable "eig_gateway_tags" {
  type        = map(string)
  default     = {}
  description = "Tags for an Egress only internet gateway"
}

variable "eip_tags" {
  type        = map(string)
  default     = {}
  description = "Tags for an Elastic Ip of an NAT Gateway"
}

variable "default_sg_tags" {
  type        = map(string)
  default     = {}
  description = "Tags for an Default Security Group"
}

variable "non_default_sg_tags" {
  type        = map(string)
  default     = {}
  description = "Tags for an Non Default Security Group"
}

variable "default_nacl_tags" {
  type        = map(string)
  default     = {}
  description = "Tags for an Default Network Access Control List"
}
