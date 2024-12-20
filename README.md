# Project Vending Repository

## Overview
The **Sandbox Vending Machine** is a sandbox environment created using Terraform. It organizes your Google Cloud resources into structured folders and projects, enabling experimentation and testing in a clean, isolated environment. This setup is perfect for Proof of Concept (PoC), Proof of Value (PoV), R&D, or general exploration without impacting production resources.

### Features 
- **Automated Provisioning**: Terraform automates the creation of folders and projects for the sandbox.
- **Isolated Environment**: Resources are structured to maintain separation from production.
- **Customizable Configuration**: Easily adjust settings to fit different sandbox needs.
- **Resource Organization**: Projects are organized under designated folders to ensure logical grouping and clarity.
### Architecture
![Logo](https://storage.googleapis.com/sachinsoni-sb-bucket-test-poc/sb-image.png)

The above image depicts the sandbox structure created by Terraform. It includes:

- **Root Folder**: A dedicated folder for sandbox projects.
- **Project Hierarchy**: Multiple projects for PoC, testing, and R&D under the sandbox folder.
- **Policies and Budgets**: Configured to enforce sandbox restrictions.



## Repository Structure
## Modules
### Folders Module

This module creates Google Cloud folders.

- **Source:** `terraform-google-modules/folders/google`

#### Variables

- `organization_id`: The ID of the Google Cloud organization.
- `parent_id`: The ID of the parent folder or organization.
- `folder_name`: The name of the folder to create.

### Project Factory Module

This module creates Google Cloud projects.

- **Source:** `terraform-google-modules/project-factory/google`

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

### `Cloud function Code`

- `fn_code/fn_proj_age_deleter/main.py`: Deletes a Google Cloud project based on the age if crosses the age of 30 days from the date of creation.
- `fn_code/fn_proj_budget_deleter` : This Cloud Function is triggered by messages published to a Cloud Pub/Sub topic when a budget alert threshold is exceeded. Upon receiving a notification indicating that 100% of the budget has been utilized (threshold `1.0`), the function identifies the associated project and deletes it.

### `deletion_script.sh`
### Overview

This script deletes JSON files associated with disabled projects from a GitHub repository. It reads project IDs from a file, locates corresponding JSON files`({project_id}.tmpl.json)` in specified directories, retrieves their SHA values, and deletes them via the GitHub API.

### Prerequisites

- **GitHub Token**: Requires a token with permissions to delete repository content.
- **Environment Variables**:
    - GITHUB_TOKEN: For authentication.
    - OWNER, REPO, BRANCH: Repository details.

- **Dependencies**:
    - jq: For parsing JSON responses.
    - Input File: disabled_projects.txt
    - Contains project IDs, one per line in the `disabled_projects.txt` file.

### Workflow

- **Read Project IDs**: From disabled_projects.txt.

- **Locate Files**: Searches for `{project_id}.tmpl.json` in specified directories.

- **Fetch SHA**: Retrieves SHA of each file via the GitHub API.

- **Delete File**: Deletes the file using its SHA.


This script deletes files related to disabled projects from GitHub.

## GitHub Actions

### `.github/workflows/terraform.yml`

### Overview  

This **Terraform CI** GitHub Actions workflow automates the management and deployment of infrastructure using Terraform. The workflow supports two directories (`gp-vending` and `sandbox-vending`) and includes a cleanup step that checks for stale or unnecessary files before executing Terraform commands.  

The workflow is designed to:  
- Run on **push** to the `main` branch or feature branches (`feature/**`).  
- Execute for **pull requests** and custom repository dispatch events (e.g., `trigger-gitops`).  
- Perform cleanup using a shell script before initializing, formatting, and planning Terraform configurations.  

---

### Key Features  

1. **Branch and Event Triggers:**  
   - Executes on `push` events to `main` and `feature/**` branches.  
   - Triggered by `pull_request` and `repository_dispatch` events.  

2. **Environment Cleanup:**  
   - Uses a shell script (`deletion_script.sh`) to clean up unnecessary files.  
   - Conditional Terraform execution based on cleanup results.  

3. **Terraform Execution:**  
   - Initializes, formats, and plans Terraform configurations for two directories: `gp-vending` and `sandbox-vending`.  

4. **Google Cloud Authentication:**  
   - Authenticates using a Google Cloud service account and workload identity provider.  

---

### Workflow Details  

**Triggering Events** 

The workflow is triggered by the following events:  
- **Push** to `main` or `feature/**` branches.  
- **Pull Request** creation or updates.  
- **Repository Dispatch:** Custom event type `trigger-gitops`.  
