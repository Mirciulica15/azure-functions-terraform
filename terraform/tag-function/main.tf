resource "azurerm_resource_group" "main" {
  name     = "rg-${var.workload}-${var.environment}-${var.region}"
  location = "${var.region}"
}

resource "azurerm_storage_account" "main" {
  name                     = "st-${var.workload}-${var.environment}-${var.region}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Basic"
  account_replication_type = "LRS"
}

resource "azurerm_function_app" "main" {
  name                        = "func-${var.workload}-${var.environment}-${var.region}"
  storage_account_name        = azurerm_storage_account.main.name
  storage_account_access_key  = azurerm_storage_account.main.primary_access_key
  location                    = azurerm_resource_group.main.location
  resource_group_name         = azurerm_resource_group.main.name
  app_service_plan_id         = azurerm_app_service_plan.main.id
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

resource "azurerm_storage_queue" "main" {
  name                 = "stq-${var.workload}-${var.environment}-${var.region}"
  storage_account_name = azurerm_storage_account.main.name
}

resource "azurerm_subscription" "main" {
  subscription_name = "DevOps and Infra CA - Bogdan Dragos"
}

resource "azurerm_eventgrid_event_subscription" "example" {
  name  = "evgs-${var.workload}-${var.environment}-${var.region}"
  scope = azurerm_subscription.main.id

  storage_queue_endpoint {
    storage_account_id = azurerm_storage_account.main.id
    queue_name         = azurerm_storage_queue.main.name
  }

  azure_function_endpoint {
    function_id = azurerm_function_app.main.id
  }
}
