########################################
# Local values 
########################################
locals {
  create_vpc = var.create_vpc
}

#######################################
# VPC configuration
#######################################
resource "aws_vpc" "main_vpc" {
  count                            = local.create_vpc ? 1 : 0
  cidr_block                       = var.vpc_cidr_block
  assign_generated_ipv6_cidr_block = var.enable_ipv6
}

######################################
# Private and Public Subnet
######################################
resource "aws_subnet" "public" {
  count                           = local.create_vpc && length(var.public_subnets) > 1 ? length(var.public_subnets) : 0
  cidr_block                      = var.public_subnets[count.index]
  availability_zone               = var.azs[count.index]
  map_public_ip_on_launch         = var.enable_public_ip[count.index]
  vpc_id                          = aws_vpc.main_vpc[0].id
  assign_ipv6_address_on_creation = var.assign_ipv6_address_on_creation
  ipv6_cidr_block                 = var.enable_ipv6 && length(var.public_subnet_ipv6_prefixes) > 0 ? cidrsubnet(aws_vpc.main_vpc[0].ipv6_cidr_block, 8, var.public_subnet_ipv6_prefixes[count.index]) : null

  tags = merge(
    { Name = "public subnet" },
    var.public_subnet_tags
  )
}

resource "aws_subnet" "private" {
  count                           = local.create_vpc && length(var.private_subnets) > 1 ? length(var.private_subnets) : 0
  cidr_block                      = var.private_subnets[count.index]
  vpc_id                          = aws_vpc.main_vpc[0].id
  availability_zone               = var.azs[count.index]
  assign_ipv6_address_on_creation = var.assign_ipv6_address_on_creation
  ipv6_cidr_block                 = var.enable_ipv6 && length(var.private_subnet_ipv6_prefixes) > 0 ? cidrsubnet(aws_vpc.main_vpc[0].ipv6_cidr_block, 8, var.private_subnet_ipv6_prefixes[count.index]) : null

  tags = merge(
    { Name = "private subnet" },
    var.private_subnet_tags
  )
}

#######################################
# Internet Gateway
#######################################
resource "aws_internet_gateway" "main_internet_gateway" {
  vpc_id = aws_vpc.main_vpc[0].id
  tags = merge(
    { Name = "Internet Gateway" },
    var.internet_gateway_tags
  )
}

#######################################
# Private and public Routing Tables 
#######################################
resource "aws_route_table" "private_route_table" {
  count  = var.enable_nat && var.nat_gateway_for_each_subnet ? length(var.private_subnets) : 1
  vpc_id = aws_vpc.main_vpc[0].id
  tags = merge(
    { Name = "private route table" },
    var.private_route_table_tags
  )
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main_vpc[0].id
  tags = merge(
    { Name = "public route table" },
    var.public_route_table_tags
  )
}

#######################################
# Routing Table association
#######################################
resource "aws_route_table_association" "public_route_table_association" {
  count          = var.enable_public_route ? length(aws_subnet.public) : 0
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_route_table_association" {
  count          = var.enable_nat && var.nat_gateway_for_each_subnet ? length(var.private_subnets) : 1
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_route_table[count.index].id
}

#######################################
# Routes
#######################################
resource "aws_route" "public_route" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.public_route_table.id
  gateway_id             = aws_internet_gateway.main_internet_gateway.id
}

resource "aws_route" "private_route" {
  count                  = var.enable_nat && var.nat_gateway_for_each_subnet ? length(var.private_subnets) : 1
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.private_route_table[count.index].id
  gateway_id             = aws_nat_gateway.private_nat[count.index].id
}

#######################################
# NAT Gateway
#######################################
resource "aws_nat_gateway" "private_nat" {
  count         = var.enable_nat && var.nat_gateway_for_each_subnet ? length(aws_subnet.private) : 0
  allocation_id = aws_eip.eip_for_nat[count.index].id
  subnet_id     = aws_subnet.private[count.index].id
  depends_on    = [aws_internet_gateway.main_internet_gateway]

  tags = merge(
    { Name = "Nat Gateway" },
    var.nat_gateway_tags
  )
}

#######################################
# Elastic Ip for an NAT GT
#######################################
resource "aws_eip" "eip_for_nat" {
  count = var.enable_nat && var.nat_gateway_for_each_subnet ? length(var.private_subnets) : 0
  vpc   = true

  tags = merge(
    { Name = "elastic ip" },
    var.eip_tags
  )
}

#######################################
# Egress only internet gateway
#######################################
resource "aws_egress_only_internet_gateway" "egress_ig" {
  vpc_id = aws_vpc.main_vpc[0].id

  tags = merge(
    { Name = "EIG for IPV6" },
    var.eig_gateway_tags
  )
}

#######################################
# IPV6 public and private route
#######################################
resource "aws_route" "ipv6_private_route_egress" {
  count                       = var.enable_ipv6 && var.single_nat_gateway && length(var.private_subnets) > 1 ? 1 : var.nat_gateway_for_each_subnet ? length(var.private_subnets) : null
  route_table_id              = aws_route_table.private_route_table[count.index].id
  egress_only_gateway_id      = aws_egress_only_internet_gateway.egress_ig.id
  destination_ipv6_cidr_block = "::/0"
  depends_on                  = [aws_route_table.private_route_table]
}

resource "aws_route" "public_internet_route_ipv6" {
  count                       = var.enable_ipv6 && length(var.public_subnets) > 1 ? 1 : null
  route_table_id              = aws_route_table.public_route_table.id
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = aws_internet_gateway.main_internet_gateway.id
  depends_on                  = [aws_route_table.public_route_table]
}

#######################################
# Security Groups
#######################################
resource "aws_default_security_group" "default" {
  count  = local.create_vpc && var.manage_default_security_group ? 1 : 0
  vpc_id = aws_vpc.main_vpc[0].id

  dynamic "ingress" {
    for_each = var.ingress_security_group_rules
    content {
      description      = lookup(ingress.value, "description", null)
      from_port        = lookup(ingress.value, "from_port", 0)
      to_port          = lookup(ingress.value, "to_port", 0)
      protocol         = lookup(ingress.value, "protocol", -1)
      cidr_blocks      = compact(split(",", lookup(ingress.value, "cidr_blocks", "")))
      ipv6_cidr_blocks = compact(split(",", lookup(ingress.value, "ipv6_cidr_blocks", "")))
      prefix_list_ids  = compact(split(",", lookup(ingress.value, "prefix_list_ids", "")))
      security_groups  = compact(split(",", lookup(ingress.value, "security_groups", "")))
    }
  }

  dynamic "egress" {
    for_each = var.egress_security_group_rules
    content {
      description      = lookup(egress.value, "description", null)
      from_port        = lookup(egress.value, "from_port", 0)
      to_port          = lookup(egress.value, "to_port", 0)
      protocol         = lookup(egress.value, "protocol", -1)
      cidr_blocks      = compact(split(",", lookup(egress.value, "cidr_blocks", "")))
      ipv6_cidr_blocks = compact(split(",", lookup(egress.value, "ipv6_cidr_blocks", "")))
      prefix_list_ids  = compact(split(",", lookup(egress.value, "prefix_list_ids", "")))
      security_groups  = compact(split(",", lookup(egress.value, "security_groups", "")))
    }
  }

  tags = merge(
    { Name = "Default SG for an VPC" },
    var.default_sg_tags
  )
}

resource "aws_security_group" "sg" {
  vpc_id = aws_vpc.main_vpc[0].id

  dynamic "ingress" {
    for_each = var.create_inbound_sg_rules
    content {
      description      = lookup(ingress.value, "description", null)
      from_port        = lookup(ingress.value, "from_port", 0)
      to_port          = lookup(ingress.value, "to_port", 0)
      protocol         = lookup(ingress.value, "protocol", -1)
      cidr_blocks      = compact(split(",", lookup(ingress.value, "cidr_blocks", "")))
      ipv6_cidr_blocks = compact(split(",", lookup(ingress.value, "ipv6_cidr_blocks", "")))
      prefix_list_ids  = compact(split(",", lookup(ingress.value, "prefix_list_ids", "")))
      security_groups  = compact(split(",", lookup(ingress.value, "security_groups", "")))
    }
  }

  dynamic "egress" {
    for_each = var.create_outbound_sg_rules
    content {
      description      = lookup(egress.value, "description", null)
      from_port        = lookup(egress.value, "from_port", 0)
      to_port          = lookup(egress.value, "to_port", 0)
      protocol         = lookup(egress.value, "protocol", -1)
      cidr_blocks      = compact(split(",", lookup(egress.value, "cidr_blocks", "")))
      ipv6_cidr_blocks = compact(split(",", lookup(egress.value, "ipv6_cidr_blocks", "")))
      prefix_list_ids  = compact(split(",", lookup(egress.value, "prefix_list_ids", "")))
      security_groups  = compact(split(",", lookup(egress.value, "security_groups", "")))
    }
  }

  tags = merge(
    { Name = "Non Default SG for an VPC" },
    var.non_default_sg_tags
  )
}

#######################################
# Network Access Control List
#######################################
resource "aws_default_network_acl" "default_acl" {
  count = local.create_vpc && var.manage_default_network_acl ? 1 : 0

  default_network_acl_id = aws_vpc.main_vpc[0].default_network_acl_id

  dynamic "ingress" {
    for_each = var.default_ingress_nacl_rules

    content {
      action          = ingress.value.action
      cidr_block      = lookup(ingress.value, "cidr_block", null)
      icmp_code       = lookup(ingress.value, "icmp_code", null)
      icmp_type       = lookup(ingress.value, "icmp_type", null)
      ipv6_cidr_block = lookup(ingress.value, "ipv6_cidr_block", null)
      protocol        = ingress.value.protocol
      rule_no         = ingress.value.rule_no
      to_port         = ingress.value.to_port
      from_port = ingress.value.from_port
    }
  }

  dynamic "egress" {
    for_each = var.default_egress_nacl_rules

    content {
      action          = egress.value["action"]
      cidr_block      = lookup(egress.value, "cidr_block", null)
      icmp_code       = lookup(egress.value, "icmp_code", null)
      icmp_type       = lookup(egress.value, "icmp_type", null)
      ipv6_cidr_block = lookup(egress.value, "ipv6_cidr_block", null)
      protocol        = egress.value.protocol
      rule_no         = egress.value.rule_no
      to_port         = egress.value.to_port
      from_port = egress.value["from_port"]
    }
  }

  tags = merge(
    { Name = "Default NACL's for an VPC" },
    var.default_nacl_tags
  )

}

resource "aws_network_acl" "public_acl" {
  count      = local.create_vpc && var.public_dedicated_network_acl && length(var.public_subnets) > 0 ? 1 : 0
  vpc_id     = aws_vpc.main_vpc[0].id
  subnet_ids = aws_subnet.public[*].id
}

resource "aws_network_acl_rule" "public_inbound" {
  count = local.create_vpc && var.public_dedicated_network_acl && length(var.public_subnets) > 0 ? length(var.public_inbound_acl_rules) : 0

  network_acl_id = aws_network_acl.public_acl[0].id

  egress          = false
  rule_number     = var.public_inbound_acl_rules[count.index]["rule_number"]
  rule_action     = var.public_inbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(var.public_inbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(var.public_inbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(var.public_inbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(var.public_inbound_acl_rules[count.index], "icmp_type", null)
  protocol        = var.public_inbound_acl_rules[count.index].protocol
  cidr_block      = lookup(var.public_inbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(var.public_inbound_acl_rules[count.index], "ipv6_cidr_block", null)
}

resource "aws_network_acl_rule" "public_outbound" {
  count = local.create_vpc && var.public_dedicated_network_acl && length(var.public_subnets) > 0 ? length(var.public_outbound_acl_rules) : 0

  network_acl_id = aws_network_acl.public_acl[0].id

  egress          = false
  rule_number     = var.public_outbound_acl_rules[count.index]["rule_number"]
  rule_action     = var.public_outbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(var.public_outbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(var.public_outbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(var.public_outbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(var.public_outbound_acl_rules[count.index], "icmp_type", null)
  protocol        = var.public_outbound_acl_rules[count.index].protocol
  cidr_block      = lookup(var.public_outbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(var.public_outbound_acl_rules[count.index], "ipv6_cidr_block", null)
}

resource "aws_network_acl" "private_acl" {
  count      = local.create_vpc && var.private_dedicated_network_acl && length(var.private_subnets) > 0 ? 1 : 0
  vpc_id     = aws_vpc.main_vpc[0].id
  subnet_ids = aws_subnet.private[*].id
}

resource "aws_network_acl_rule" "private_inbound" {
  count = local.create_vpc && var.private_dedicated_network_acl && length(var.public_subnets) > 0 ? length(var.private_inbound_acl_rules) : 0

  network_acl_id = aws_network_acl.private_acl[0].id

  egress          = false
  rule_number     = var.private_inbound_acl_rules[count.index]["rule_number"]
  rule_action     = var.private_inbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(var.private_inbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(var.private_inbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(var.private_inbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(var.private_inbound_acl_rules[count.index], "icmp_type", null)
  protocol        = var.private_inbound_acl_rules[count.index].protocol
  cidr_block      = lookup(var.private_inbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(var.private_inbound_acl_rules[count.index], "ipv6_cidr_block", null)
}

resource "aws_network_acl_rule" "private_outbound" {
  count = local.create_vpc && var.private_dedicated_network_acl && length(var.public_subnets) > 0 ? length(var.private_outbound_acl_rules) : 0

  network_acl_id = aws_network_acl.private_acl[0].id

  egress          = false
  rule_number     = var.private_outbound_acl_rules[count.index]["rule_number"]
  rule_action     = var.private_outbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(var.private_outbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(var.private_outbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(var.private_outbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(var.private_outbound_acl_rules[count.index], "icmp_type", null)
  protocol        = var.private_outbound_acl_rules[count.index].protocol
  cidr_block      = lookup(var.private_outbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(var.private_outbound_acl_rules[count.index], "ipv6_cidr_block", null)
}