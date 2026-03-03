variable "location" {
  type    = string
  default = "eastus"
}

variable "resource_group_name" {
  type    = string
  default = "rg-secure-secrets-cicd"
}

variable "key_vault_name" {
  type = string
  # must be globally unique; you can override via tfvars
  default = "kv-secure-secrets-cicd-raj"
}

# GitHub repo identity for federated auth
variable "github_org" {
  type = string
}

variable "github_repo" {
  type = string
}

variable "github_branch" {
  type    = string
  default = "main"
}