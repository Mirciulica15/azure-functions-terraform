resource "azurerm_resource_group" "main" {
  name     = "rg-${var.workload}-${var.environment}-${var.region}"
  location = "${var.region}"
}

resource "azurerm_function_app" "main" {
  name                      = "func-${var.workload}-${var.environment}-${var.region}"
  location                  = azurerm_resource_group.main.location
  resource_group_name       = azurerm_resource_group.main.name
  app_service_plan_id       = azurerm_app_service_plan.main.id
  storage_connection_string = azurerm_storage_account.main.primary_connection_string
}

resource "azurerm_app_service_plan" "main" {
  name                = "asp-${var.workload}-${var.environment}-${var.region}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  kind                = "FunctionApp"

  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

resource "azurerm_storage_account" "main" {
  name                     = "sa-${var.workload}-${var.environment}-${var.region}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Basic"
  account_replication_type = "LRS"
}
