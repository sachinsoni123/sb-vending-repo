variable "project_name" {
  type        = string
  description = "The name of the project"
}

variable "api" {
  type        = list(string)
  description = "The apis to be enabled"
}
variable "folder_id" {
  type        = string
  description = "The folder id in which the projects should be created"
}

variable "labels" {
  type        = map(string)
  description = "The folder id in which the projects should be created"
}

variable "owners_members" {
  type        = list(string)
  description = "List of users to add to the owners group"
}
