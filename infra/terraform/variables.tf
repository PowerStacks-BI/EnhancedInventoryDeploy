variable "workspace_name" {
  type        = string
  description = "Name of the existing Log Analytics workspace to deploy into."
}

variable "workspace_resource_group_name" {
  type        = string
  description = "Resource group of the existing Log Analytics workspace. The DCE and DCR are created here too, co-located with the workspace."
}

variable "dce_name" {
  type        = string
  description = "Name of the Data Collection Endpoint to create."
  default     = "dce-PowerStacksInventory"
}

variable "dcr_name" {
  type        = string
  description = "Name of the Data Collection Rule to create."
  default     = "dcr-PowerStacksInventory"
}

variable "enterprise_app_object_id" {
  type        = string
  description = "Optional. Object ID of the Enterprise Application (service principal) that writes inventory. NOT the Application (Client) ID. When set, the module assigns Monitoring Metrics Publisher on the DCR. Leave blank to assign it manually later."
  default     = ""
}
