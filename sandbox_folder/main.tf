module "sandbox_environment" {
  source          = "../modules/folders"
  organization_id = "organizations/906927793089"
  folder_name          = ["sandbox"]
  parent_id       = "organizations/906927793089"
}
