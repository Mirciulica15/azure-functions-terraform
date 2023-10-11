data "azurerm_subscription" "current" {
}

data "azurerm_windows_function_app" "main" {
  name                = "func-${var.workload}-${var.environment}-${var.region}"
  resource_group_name = "rg-${var.workload}-${var.environment}-${var.region}"
}

resource "azurerm_eventgrid_event_subscription" "main" {
  name  = "evgs-${var.workload}-${var.environment}-${var.region}"
  scope = data.azurerm_subscription.current.id

  included_event_types = [
    "Microsoft.Resources.ResourceWriteSuccess"
  ]

  azure_function_endpoint {
    function_id = "${data.azurerm_windows_function_app.main.id}/functions/tagwithcreator"
  }
}