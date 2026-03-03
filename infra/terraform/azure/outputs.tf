output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "key_vault_name" {
  value = azurerm_key_vault.kv.name
}

output "client_id" {
  value = azurerm_user_assigned_identity.gha.client_id
}

output "tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}

output "subscription_id" {
  value = data.azurerm_client_config.current.subscription_id
}