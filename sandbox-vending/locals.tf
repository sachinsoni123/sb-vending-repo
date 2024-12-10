locals {
  # Create map from the template files in the data folder
  project_vending_data_dir = "${path.module}/data/"
  project_vending_files    = fileset(local.project_vending_data_dir, "*.json")
  project_vending_data_map = {
    for f in local.project_vending_files :
    trimsuffix(f, ".json") => jsondecode(file("${local.project_vending_data_dir}/${f}"))
  }
}
