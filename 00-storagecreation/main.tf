# create resource group
resource "azurerm_resource_group" "rg1" {
  name     = "dev-env-resourcegroup"
  location = "East US"
}

# create storage account
resource "azurerm_storage_account" "sa1" {
  name                     = "statefilestorageacc1"
  resource_group_name      = azurerm_resource_group.rg1.name
  location                 = azurerm_resource_group.rg1.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  identity {
    type = "SystemAssigned"
  }

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
resource "azurerm_key_vault" "kv1" {
  name                        = "statefile-keyvault"
  location                    = azurerm_resource_group.rg1.location
  resource_group_name         = azurerm_resource_group.rg1.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  #soft_delete_retention_days  = 7
  #purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get",
      "List",
      "Create",
      "Delete",
      "Update",
      "Import",
      "Backup",
      "Restore",
      "Recover",
      "Purge"
    ]

    # these are used for fetching the token/passwords. here for statefile no need these.
    # secret_permissions = [
    #   "Get",
    # ]

    # storage_permissions = [
    #   "Get",
    # ]
  }
}
# 2. Create the Key
resource "azurerm_key_vault_key" "statefile-keyvault-key" {
  name         = "generatedtfstatekey"
  key_vault_id = azurerm_key_vault.kv1.id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "unwrapKey",
    "wrapKey",
  ]

  rotation_policy {
    automatic {
      time_before_expiry = "P30D"
    }

    expire_after         = "P90D"
    notify_before_expiry = "P29D"
  }
}

# 3. Assign Managed Identity to Storage Account
# to do this add this block of code while creating the storage account
#  identity {
#     type = "SystemAssigned"
#   }

# 4. Grant Storage Account Access to Key Vault Key
resource "azurerm_key_vault_access_policy" "storage-access" {
  key_vault_id = azurerm_key_vault.kv1.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_storage_account.sa1.identity[0].principal_id

  key_permissions = [
    "Get",
    "WrapKey",
    "UnwrapKey"
  ]
}

# 5. Link CMK(key vault) to Storage Account
resource "azurerm_storage_account_customer_managed_key" "keyvault-link" {
  storage_account_id = azurerm_storage_account.sa1.id
  key_vault_id       = azurerm_key_vault.kv1.id
  key_name           = azurerm_key_vault_key.statefile-keyvault-key.name
}