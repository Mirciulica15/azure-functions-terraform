data "azurerm_subscription" "current" {
}

resource "azurerm_eventgrid_event_subscription" "main" {
  name  = "evgs-${var.workload}-${var.environment}-${var.region}"
  scope = data.azurerm_subscription.current.id

  azure_function_endpoint {
    function_id = azurerm_linux_function_app.main.id/functions/tag
  }
}