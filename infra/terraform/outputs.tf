# These two feed the inventory script (DceURI and DcrImmutableId), the same as
# the ARM template's outputs of the same name.

output "DceURI" {
  description = "Logs ingestion endpoint of the Data Collection Endpoint. Set as DceURI in the inventory script."
  value       = azurerm_monitor_data_collection_endpoint.dce.logs_ingestion_endpoint
}

output "DcrImmutableId" {
  description = "Immutable ID of the Data Collection Rule. Set as DcrImmutableId in the inventory script."
  value       = azurerm_monitor_data_collection_rule.dcr.immutable_id
}

output "WorkspaceResourceId" {
  description = "Resource ID of the Log Analytics workspace the tables and DCR target."
  value       = data.azurerm_log_analytics_workspace.law.id
}

output "RoleAssignmentSkipped" {
  description = "Whether the Monitoring Metrics Publisher role was assigned automatically."
  value       = var.enterprise_app_object_id == "" ? "Yes - assign Monitoring Metrics Publisher on the DCR manually" : "No - assigned automatically during apply"
}
