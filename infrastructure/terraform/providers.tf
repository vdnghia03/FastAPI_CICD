terraform {
  required_version = "~> 1.12"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.3"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }


  # Cách 1: ghi trực tiếp (nhanh gọn khi demo)
  # subscription_id = "6d9441a6-21a1-452d-afea-e162cd752430"

  # Cách 2 (khuyên dùng): để trống ở đây và export ENV
  # export ARM_SUBSCRIPTION_ID=...
  # export ARM_TENANT_ID=...
  # export ARM_CLIENT_ID=...
  # export ARM_CLIENT_SECRET=...
}
