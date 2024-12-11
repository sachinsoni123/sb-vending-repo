module "global_practice" {
  for_each        = { for k, v in local.project_vending_data_map : k => v if v.settings.gp-vending != false }
  source          = "../modules/folders"
  organization_id = each.value.settings.gp-vending.organization_id
  folder_name     = each.value.settings.gp-vending.names_gp
  parent_id       = each.value.settings.gp-vending.parent_id
}

module "poc" {
  for_each        = { for k, v in local.project_vending_data_map : k => v if v.settings.gp-vending != false }
  source          = "../modules/folders"
  organization_id = each.value.settings.gp-vending.organization_id
  folder_name     = each.value.settings.gp-vending.names_poc
  parent_id       = module.global_practice[each.key].folder_id
}

module "app_folder" {
  for_each        = { for k, v in local.project_vending_data_map : k => v if v.settings.gp-vending != false }
  source          = "../modules/folders"
  organization_id = each.value.settings.gp-vending.organization_id
  folder_name     = each.value.settings.gp-vending.names_app
  parent_id       = module.poc[each.key].folder_id
}


module "app_project" {
  for_each       = { for k, v in local.project_vending_data_map : k => v if v.settings.gp-vending != false }
  source         = "../modules/project_factory"
  project_name   = each.value.settings.gp-vending.project_name
  api            = each.value.settings.gp-vending.api
  folder_id      = module.app_folder[each.key].folder_id
  labels         = each.value.settings.gp-vending.labels
  owners_members = each.value.settings.gp-vending.owners_members
  depends_on = [
    module.app_folder
  ]
}

module "app_budget_alert" {
  for_each        = { for k, v in local.project_vending_data_map : k => v if v.settings.gp-vending != false }
  source          = "../modules/budget"
  project_name    = each.value.settings.gp-vending.project_name
  billing_id      = each.value.settings.gp-vending.billing_id
  project_no      = module.app_project[each.key].project_number
  approved_budget = each.value.settings.gp-vending.approved_budget
  members         = each.value.settings.gp-vending.notification_members
  depends_on = [
    module.app_project
  ]
}
