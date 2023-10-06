terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.75.0"
    }
  }

  backend "azurerm" {
    resource_group_name   = "rg-common-resources"
    storage_account_name  = "tfstateaccesafunctions"
    container_name        = "my-eventContainer"
    key                   = "terraform.tfstate"
  }
}

provider "azurerm" {
  skip_provider_registration = true
  features {}
}
