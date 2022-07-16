output "public_subnets" {
  description = "public_subnet"
  value       = aws_subnet.public[*].id
}

output "private_subnets" {
  description = "private subnet"
  value       = aws_subnet.private[*]
}

output "main_vpc" {
  description = "this is the main vpc"
  value       = aws_vpc.main_vpc[0]
}

output "public_route_table_association" {
  description = "public route table association"
  value       = aws_route_table_association.public_route_table_association[*]
}

output "private_route_table_association" {
  description = "private route table association"
  value       = aws_route_table_association.private_route_table_association[*]
}

output "sg" {
  description = "non-default security group rules"
  value       = aws_security_group.sg
}

output "public_inbound_acl_rules" {
  description = "public inbound network acl rules"
  value       = aws_network_acl_rule.public_inbound[*]
}

output "public_outbound_acl_rules" {
  description = "public outbound network acl rules"
  value       = aws_network_acl_rule.public_outbound[*]
}

output "private_inbound_acl_rules" {
  description = "private inbound network acl rules"
  value       = aws_network_acl_rule.private_inbound[*]
}

output "private_outbound_acl_rules" {
  description = "private outbound network acl rules"
  value       = aws_network_acl_rule.private_outbound[*]
}

output "nat_gateway" {
  value       = aws_nat_gateway.private_nat[*]
  description = "Nat gateway created in the vpc"
}

output "internet_gateway" {
  value       = aws_internet_gateway.main_internet_gateway
  description = "internet gateway of an vpc"
}