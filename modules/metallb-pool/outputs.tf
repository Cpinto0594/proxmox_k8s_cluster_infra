output "pool_name" {
  description = "Name of the IPAddressPool."
  value       = local.pool_name
}

output "addresses" {
  description = "Address ranges assigned to the pool."
  value       = local.metallb_addresses
}
