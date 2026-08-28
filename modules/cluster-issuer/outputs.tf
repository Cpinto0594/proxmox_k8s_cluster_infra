output "issuers" {
  description = "Names of the ClusterIssuers created."
  value       = sort(keys(local.issuers))
}

output "staging" {
  description = "Name of the Let's Encrypt staging ClusterIssuer."
  value       = "letsencrypt-staging"
}

output "prod" {
  description = "Name of the Let's Encrypt production ClusterIssuer."
  value       = "letsencrypt-prod"
}
