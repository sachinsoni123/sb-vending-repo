locals {
  org_id                  = data.google_organization.opsdev.org_id
  billing_account         = data.google_billing_account.sixty_six_degrees_billing_account.id
}

data "google_organization" "opsdev" {
  domain = "opsdev.cloudbakers.com"
}

data "google_billing_account" "sixty_six_degrees_billing_account" {
  billing_account = "012BAE-CAC265-849A70"
  open            = true
  lookup_projects = false
}

module "projects" {
  source  = "terraform-google-modules/project-factory/google"
  version = "17.0.0"
  auto_create_network = true
  random_project_id = false
  activate_apis     = var.api
  name              = var.project_name
  org_id            = local.org_id
  billing_account   = local.billing_account
  folder_id         = var.folder_id
  deletion_policy = "DELETE"

  labels = var.labels
}

resource "google_project_iam_member" "project_owners" {
  project = module.projects.project_id
  role    = "roles/viewer"

  for_each = toset(var.owners_members)

  member = each.value
}
