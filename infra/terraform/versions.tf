# Terraform equivalent of infra/main.bicep (PowerStacks Enhanced Inventory).
# Creates the Data Collection Endpoint, Data Collection Rule, the three custom
# Log Analytics tables, and the optional Monitoring Metrics Publisher role
# assignment, against an existing Log Analytics workspace.
#
# The custom _CL tables are created with the azapi provider, because the azurerm
# provider cannot create custom-schema Log Analytics tables. Everything else is
# native azurerm.

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  features {}
  # azurerm v4 needs a subscription. Set it here, or via the ARM_SUBSCRIPTION_ID
  # environment variable:
  # subscription_id = "00000000-0000-0000-0000-000000000000"
}

provider "azapi" {}
