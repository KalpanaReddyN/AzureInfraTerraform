# create resource group
resource "azurerm_resource_group" "rg1" {
  name     = "dev-env-resourcegroup"
  location = "East US"
}

# create storage account
resource "azurerm_storage_account" "sa1" {
  name                     = "statefilestorageacc"
  resource_group_name      = azurerm_resource_group.rg1.name
  location                 = azurerm_resource_group.rg1.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = {
    environment = "development"
  }
}

# create blob/container in storage account
resource "azurerm_storage_container" "sc1" {
  name                  = "tfstatestoragecontainer"
  storage_account_id    = azurerm_storage_account.sa1.id
  container_access_type = "private"
}

# Default microsoft provides Storage Account Encryption (enabled by default with Microsoft-managed keys MMK)
# For customer-managed keys CMK, you'd use azurerm_key_vault_key and link it here.
# 1. Create Key Vault
# resource "azurerm_key_vault" "kv1" {
#   name                        = "statefile-keyvault"
#   location                    = azurerm_resource_group.rg1.location
#   resource_group_name         = azurerm_resource_group.rg1.name
#   enabled_for_disk_encryption = true
#   tenant_id                   = data.azurerm_client_config.current.tenant_id
#   #soft_delete_retention_days  = 7
#   #purge_protection_enabled    = false

#   sku_name = "standard"

#   access_policy {
#     tenant_id = data.azurerm_client_config.current.tenant_id
#     object_id = data.azurerm_client_config.current.object_id

#     key_permissions = [
#       "get",
#       "list",
#       "create",
#       "delete",
#       "update",
#       "import",
#       "backup",
#       "restore",
#       "recover",
#       "purge"
#     ]

#     # these are used for fetching the token/passwords. here for statefile no need these.
#     # secret_permissions = [
#     #   "Get",
#     # ]

#     # storage_permissions = [
#     #   "Get",
#     # ]
#   }
# }