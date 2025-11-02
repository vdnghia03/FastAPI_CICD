terraform {
  backend "azurerm" {
    resource_group_name  = "tfstates"               # RG chứa storage account
    storage_account_name = "tfstatescoursebk"         # hoặc "tfstatescoursebk" tùy bạn
    container_name       = "tfstate-aks-lab"        # container riêng cho dự án này
    key                  = "dev.terraform.tfstate"  # file state bên trong container
  }
}


