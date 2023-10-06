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
  sku_name            = "P1v2"
}

resource "azurerm_linux_function_app" "main" {
  name                = "func-${var.workload}-${var.environment}-${var.region}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  storage_account_name       = azurerm_storage_account.main.name
  storage_account_access_key = azurerm_storage_account.main.primary_access_key
  service_plan_id            = azurerm_service_plan.main.id

  site_config {}
}

# resource "azurerm_subscription" "main" {
#   subscription_name = "DevOps and Infra CA - Bogdan Dragos"
#   subscription_id   =  "becac16d-bf7b-4be5-ac53-982193486642"
# }

resource "azurerm_eventgrid_event_subscription" "main" {
  name  = "evgs-${var.workload}-${var.environment}-${var.region}"
  scope = azurerm_resource_group.main.id

  azure_function_endpoint {
    function_id = azurerm_linux_function_app.main.id
  }
}
