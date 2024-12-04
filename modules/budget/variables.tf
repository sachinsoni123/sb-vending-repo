variable "members" {
  description = "List of email addresses for notification members"
  type        = list(string)
}
variable "billing_id" {
  description = "The ID of the folder in which the resource belongs. If it is not provided, the provider project is used."
  type        = string
}
variable "project_name" {
  description = "The name of the project in which the resource belongs. If it is not provided, the provider project is used."
  type        = string
}
variable "project_no" {
  description = "The no of the project in which the resource belongs. If it is not provided, the provider project is used."
  type        = string
  default     = ""
}
variable "approved_budget" {
  description = "Amount of budget approved for this project"
  default     = "100"
}
