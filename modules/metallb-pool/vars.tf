variable "namespace" {
  description = "Namespace MetalLB runs in."
  type        = string
  default     = "networking"
}

variable "pool_name" {
  description = "Name for the IPAddressPool and L2Advertisement."
  type        = string
  default     = "lan"
}

variable "metallb_addresses" {
  description = "Address ranges MetalLB may assign (from common.hcl), e.g. [\"192.168.30.200-192.168.30.250\"]."
  type        = list(string)
}
