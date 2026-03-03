resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  name                       = var.key_vault_name
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  purge_protection_enabled   = false
  soft_delete_retention_days = 7
}

# Example secret (placeholder) — we’ll update later
resource "azurerm_key_vault_secret" "demo_secret" {
  name         = "demo-api-key"
  value        = "replace-me-later"
  key_vault_id = azurerm_key_vault.kv.id
}

# Azure AD Application for GitHub OIDC federation
resource "azurerm_user_assigned_identity" "gha" {
  name                = "uai-gha-secure-secrets"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Allow the identity to read secrets in Key Vault
resource "azurerm_role_assignment" "kv_secrets_user" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.gha.principal_id
}

# Federated credential so GitHub Actions can login without secrets
resource "azurerm_federated_identity_credential" "github" {
  name                = "github-oidc"
  resource_group_name = azurerm_resource_group.rg.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  parent_id           = azurerm_user_assigned_identity.gha.id
  subject             = "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/${var.github_branch}"
}