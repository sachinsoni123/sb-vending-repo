module "sandbox_folder" {
  for_each        = local.project_vending_data_map
  source          = "../modules/folders"
  organization_id = each.value.settings.organization_id
  folder_name     = each.value.settings.names
  parent_id       = each.value.settings.parent_id
}

module "sandbox_project" {
  for_each       = local.project_vending_data_map
  source         = "../modules/project_factory"
  project_name   = each.value.settings.project_name
  api            = each.value.settings.api
  folder_id      = module.sandbox_folder[each.key].folder_id
  labels         = each.value.settings.labels
  owners_members = each.value.settings.owners_members
  depends_on = [
    module.sandbox_folder
  ]
}

module "sandbox_budget_alert" {
  for_each        = local.project_vending_data_map
  source          = "../modules/budget"
  project_name    = each.value.settings.project_name
  billing_id      = each.value.settings.billing_id
  project_no      = module.sandbox_project[each.key].project_number
  approved_budget = each.value.settings.approved_budget
  members         = each.value.settings.notification_members
  depends_on = [
    module.sandbox_project
  ]
}
