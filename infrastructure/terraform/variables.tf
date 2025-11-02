variable "prefix_app_name" {
  description = "Prefix đặt trước tên các resource"
  type        = string
}

variable "location" {
  description = "Region cho các resource Azure"
  type        = string
}

variable "node_count" {
  description = "Số lượng node trong AKS cluster"
  type        = number
}

variable "vm_size" {
  description = "Loại VM cho node pool"
  type        = string
}
