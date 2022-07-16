variable "default_ingress_sg_rules" {
  type = list(map(string))
}

variable "default_egress_sg_rules" {
  type = list(map(string))
}

variable "default_ingress_nacl_rules" {
  type = list(map(string))
}

variable "default_egress_nacl_rules" {
  type = list(map(string))
}