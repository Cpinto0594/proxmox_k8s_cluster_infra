output "pool_name" {
  description = "Name of the IPAddressPool."
  value       = var.pool_name
}

output "addresses" {
  description = "Address ranges assigned to the pool."
  value       = var.addresses
}
