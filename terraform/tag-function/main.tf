resource "azurerm_resource_group" "main" {
  name     = "rg-${var.workload}-${var.environment}-${var.region}"
  location = "${var.region}"
}

locals {
  stName = "${var.workload}${var.environment}${var.region}"
  sanitized_stName = replace(local.stName, "-", "")
}

resource "azurerm_storage_account" "main" {
  name                     = "st${local.sanitized_stName}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_service_plan" "main" {
  name                = "asp-${var.workload}-${var.environment}-${var.region}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "EP1"
}

resource "azurerm_linux_function_app" "main" {
  name                = "func-${var.workload}-${var.environment}-${var.region}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  storage_account_name       = azurerm_storage_account.main.name
  storage_account_access_key = azurerm_storage_account.main.primary_access_key
  service_plan_id            = azurerm_service_plan.main.id

  site_config {}

  connection_string {
    name  = "MyStorageAccountConnection"
    type  = "Custom"
    value = "DefaultEndpointsProtocol=https;AccountName=${azurerm_storage_account.main.name};AccountKey=${azurerm_storage_account.main.primary_access_key};EndpointSuffix=core.windows.net"
  }
}
