output "name" {
  value       = module.wiz_connector.name
  description = "Name of the connector that was created"
}

output "id" {
  value       = module.wiz_connector.id
  description = "ID of the connector that was created"
}

output "outpost_id" {
  value       = module.wiz_connector.outpost_id
  description = "ID of the Wiz Outpost that was used for this connector"
}

output "wiz_role_arn" {
  value       = module.wiz.role_arn
  description = "ARN that was created that will be used by the Wiz connector"
}
