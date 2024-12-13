# Project Vending Repository

This repository contains Terraform configurations and Python scripts for managing Google Cloud projects, folders, and budgets. It includes modules for creating and managing projects, folders, and budgets, as well as scripts for cleaning up disabled projects.

## Repository Structure
## Modules

### Folders Module

This module creates Google Cloud folders.

- **Source:** `terraform-google-modules/folders/google`
- **Version:** `5.0.0`

#### Variables

- `organization_id`: The ID of the Google Cloud organization.
- `parent_id`: The ID of the parent folder or organization.
- `folder_name`: The name of the folder to create.

### Project Factory Module

This module creates Google Cloud projects.

- **Source:** `terraform-google-modules/project-factory/google`
- **Version:** `17.0.0`

#### Variables

- `project_name`: The name of the project.
- `api`: List of APIs to enable.
- `folder_id`: The ID of the folder in which the project should be created.
- `labels`: Labels to apply to the project.
- `owners_members`: List of users to add to the owners group.

### Budget Module

This module creates budget alerts for Google Cloud projects.

#### Variables

- `members`: List of email addresses for notification members.
- `billing_id`: The ID of the billing account.
- `project_name`: The name of the project.
- `project_no`: The number of the project.
- `approved_budget`: The approved budget amount.

## Scripts

### `fn_code/main.py`

This script contains functions for managing Google Cloud projects and budgets.

- `delete_project(project_id)`: Deletes a Google Cloud project.
- `get_budget_utilization(project_id, billing_account_id)`: Gets the budget utilization for a project.
- `list_projects_in_organization(org_id, billing_account_id)`: Lists all projects in the specified organization and billing account.
- `main_entry(request)`: Main entry point for the script.

### `deletion_script.sh`

This script deletes files related to disabled projects from GitHub.

## GitHub Actions

### `.github/workflows/terraform.yml`

This workflow runs Terraform commands to manage the infrastructure.

## Usage

1. Clone the repository.
2. Install the required Python packages:
    ```sh
    pip install -r fn_code/requirements.txt
    ```
3. Run the main script:
    ```sh
    python fn_code/main.py
    ```