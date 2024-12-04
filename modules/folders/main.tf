module "folder" {
  source  = "terraform-google-modules/folders/google"
  version = "5.0.0"

  # Variables for creating Sandbox folder
  names  = var.folder_name
  parent = var.parent_id

  # Allow Terraform to create and destroy this folder
  deletion_protection = false
}
