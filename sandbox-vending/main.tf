module "sandbox_folder" {
  for_each        = { for k, v in local.project_vending_data_map : k => v if v.settings.sandbox-vending != false }
  source          = "../modules/folders"
  organization_id = each.value.settings.sandbox-vending.organization_id
  folder_name     = each.value.settings.sandbox-vending.names
  parent_id       = each.value.settings.sandbox-vending.parent_id
}

module "sandbox_project" {
  for_each       = { for k, v in local.project_vending_data_map : k => v if v.settings.sandbox-vending != false }
  source         = "../modules/project_factory"
  project_name   = each.value.settings.sandbox-vending.project_name
  api            = each.value.settings.sandbox-vending.api
  folder_id      = module.sandbox_folder[each.key].folder_id
  labels         = each.value.settings.sandbox-vending.labels
  owners_members = each.value.settings.sandbox-vending.owners_members
  depends_on = [
    module.sandbox_folder
  ]
}

module "sandbox_budget_alert" {
  for_each        = { for k, v in local.project_vending_data_map : k => v if v.settings.sandbox-vending != false }
  source          = "../modules/budget"
  project_name    = each.value.settings.sandbox-vending.project_name
  billing_id      = each.value.settings.sandbox-vending.billing_id
  project_no      = module.sandbox_project[each.key].project_number
  approved_budget = each.value.settings.sandbox-vending.approved_budget
  members         = each.value.settings.sandbox-vending.notification_members
  depends_on = [
    module.sandbox_project
  ]
}

