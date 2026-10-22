terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=5.10.0"
    }

    azuread = {
      source  = "hashicorp/azuread"
      version = "= 3.10.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azuread" {
}

data "azuread_client_config" "current" {}

output "authenticated_principal" {
  value = {
    client_id = data.azuread_client_config.current.client_id
    object_id = data.azuread_client_config.current.object_id
    tenant_id = data.azuread_client_config.current.tenant_id
  }
}

resource "azuread_group" "platform_engineers" {
  display_name     = "Lab-Platform-Engineers"
  security_enabled = true
}
