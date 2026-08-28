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

variable "addresses" {
  description = "Address ranges MetalLB may assign, e.g. [\"192.168.1.240-192.168.1.250\"]."
  type        = list(string)
}
