output "name" {
  value       = wiz_aws_connector.connector.name
  description = "Name of the connector that was created"
}

output "id" {
  value       = wiz_aws_connector.connector.id
  description = "ID of the connector that was created"
}

output "outpost_id" {
  value       = one([for v in wiz_aws_connector.connector.auth_params : v.outpost_id])
  description = "ID of the Wiz Outpost that was used for this connector"
}
