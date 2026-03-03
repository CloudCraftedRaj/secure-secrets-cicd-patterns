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
  enable_rbac_authorization  = true
}

resource "azurerm_key_vault" "kv_prod" {
  name                       = var.key_vault_name_prod
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"

  enable_rbac_authorization  = true
  purge_protection_enabled   = false
  soft_delete_retention_days = 7
}

# Example secret (placeholder) — we’ll update later
resource "azurerm_key_vault_secret" "demo_secret" {
  name         = "demo-api-key"
  value        = "replace-me-later"
  key_vault_id = azurerm_key_vault.kv.id
  depends_on = [
    azurerm_role_assignment.current_user_kv_secrets_officer
  ]
}

resource "azurerm_key_vault_secret" "prod_secret" {
  name         = "demo-api-key"
  value        = "prod-value-placeholder"
  key_vault_id = azurerm_key_vault.kv_prod.id

  depends_on = [azurerm_role_assignment.current_user_kv_secrets_officer_prod]
}

# Azure AD Application for GitHub OIDC federation
resource "azurerm_user_assigned_identity" "gha" {
  name                = "uai-gha-secure-secrets"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_user_assigned_identity" "gha_prod" {
  name                = "uai-gha-secure-secrets-prod"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Allow the identity to read secrets in Key Vault
resource "azurerm_role_assignment" "kv_secrets_user" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.gha.principal_id
  depends_on           = [azurerm_key_vault.kv]
}

resource "azurerm_role_assignment" "kv_prod_secrets_user" {
  scope                = azurerm_key_vault.kv_prod.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.gha_prod.principal_id
  depends_on           = [azurerm_key_vault.kv_prod]
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

resource "azurerm_federated_identity_credential" "github_prod" {
  name                = "github-oidc-prod"
  resource_group_name = azurerm_resource_group.rg.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  parent_id           = azurerm_user_assigned_identity.gha_prod.id
  subject             = "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/${var.github_branch}"
}

resource "azurerm_role_assignment" "current_user_kv_secrets_officer" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "current_user_kv_secrets_officer_prod" {
  scope                = azurerm_key_vault.kv_prod.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}