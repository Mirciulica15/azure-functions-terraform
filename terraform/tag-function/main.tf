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
  os_type             = "Windows"
  sku_name            = "Y1"
}

resource "azurerm_application_insights" "main" {
  name                = "appi-func-${var.workload}-${var.environment}-${var.region}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "other"
}

resource "azurerm_windows_function_app" "main" {
  name                = "func-${var.workload}-${var.environment}-${var.region}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  storage_account_name       = azurerm_storage_account.main.name
  storage_account_access_key = azurerm_storage_account.main.primary_access_key
  service_plan_id            = azurerm_service_plan.main.id

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
  }

  site_config {
    application_insights_connection_string = azurerm_application_insights.main.connection_string
  }

  identity {
    type = "SystemAssigned"
  }
}

data "azurerm_subscription" "current" {
}

resource "azurerm_role_assignment" "reader" {
  principal_id                     = azurerm_windows_function_app.main.identity[0].principal_id
  role_definition_name             = "Reader"
  scope                            = data.azurerm_subscription.current.id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "contributor" {
  principal_id                     = azurerm_windows_function_app.main.identity[0].principal_id
  role_definition_name             = "Tag Contributor"
  scope                            = data.azurerm_subscription.current.id
  skip_service_principal_aad_check = true
}

data "azurerm_client_config" "current" {
}

resource "azurerm_role_assignment" "spreader" {
  principal_id                     = azurerm_windows_function_app.main.identity[0].principal_id
  role_definition_name             = "Reader"
  scope                            = data.azurerm_client_config.current.object_id
  skip_service_principal_aad_check = true
}

data "azuread_application_published_app_ids" "well_known" {}

resource "azuread_service_principal" "msgraph" {
  application_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
  use_existing   = true
}

resource "azuread_application" "main" {
  display_name = "main"

  required_resource_access {
    resource_app_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph

    resource_access {
      id   = azuread_service_principal.msgraph.app_role_ids["User.Read.All"]
      type = "Role"
    }

    resource_access {
      id   = azuread_service_principal.msgraph.oauth2_permission_scope_ids["User.ReadWrite"]
      type = "Scope"
    }
  }
}

resource "azuread_service_principal" "main" {
  application_id = azuread_application.main.application_id
}

resource "azuread_app_role_assignment" "main" {
  app_role_id         = azuread_service_principal.msgraph.app_role_ids["User.Read.All"]
  principal_object_id = azuread_service_principal.example.object_id
  resource_object_id  = azuread_service_principal.msgraph.object_id
}
