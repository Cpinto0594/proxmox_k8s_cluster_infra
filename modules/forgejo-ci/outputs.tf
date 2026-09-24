output "service_account_name" {
  description = "Name of the Forgejo deployer ServiceAccount."
  value       = local.service_account_name
}

output "namespace" {
  description = "Namespace the deployer ServiceAccount lives in."
  value       = local.namespace
}

output "token_secret_name" {
  description = "Name of the Secret holding the deployer's long-lived token."
  value       = local.token_secret_name
}
