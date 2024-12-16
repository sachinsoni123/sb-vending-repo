# README

## Overview
This Cloud Function script automates the process of identifying and deleting Google Cloud Platform (GCP) projects within an organization that were created using Terraform and have been active for more than 30 days. The function fetches all active projects labeled `created-by: terraform`, calculates their age, and deletes projects older than 30 days.

### Key Functionalities:
1. **List Projects**: Scans the organization for active projects labeled `created-by: terraform`.
2. **Delete Projects**: Deletes projects exceeding the 30-day age limit.
3. **Scheduled Execution**: Can be triggered daily using a Cloud Scheduler.

---

## Prerequisites

### Permissions
To execute this script, the Cloud Function service account requires the following permissions:
1. **List Projects**: Access to organization-level permissions:
   - `roles/resourcemanager.projectViewer`
   - `roles/resourcemanager.folderViewer`
   - `roles/resourcemanager.organizationViewer`
2. **Delete Projects**: Access to project-level permissions:
   - `roles/resourcemanager.projectDeleter`

Additionally, the Cloud Scheduler service account needs the following:
- `roles/cloudfunctions.invoker` for invoking the Cloud Function.

### GCP Resources
1. **Cloud Function**:
   - HTTP-triggered function.
   - Environment variable: `ORG_ID` (your GCP organization ID).
2. **Cloud Scheduler**:
   - Triggers the Cloud Function daily.

### Required Libraries
Add the following dependencies to your `requirements.txt` file:
```
google-cloud-resource-manager==1.13.0
google-cloud-billing==1.14.1
google-cloud-logging==3.11.3
google-cloud-billing-budgets
```

---

## Deployment Steps

### Step 1: Set Up a Service Account
1. **Create a Service Account**:
   - Go to the [IAM & Admin](https://console.cloud.google.com/iam-admin/serviceaccounts) section in the Google Cloud Console.
   - Create a service account with the required roles mentioned above.

2. **Download the Service Account Key**:
   - Save the JSON key file securely for use during Cloud Function setup.

### Step 2: Deploy the Cloud Function
1. **Create a Cloud Function**:
   - Navigate to the [Cloud Functions](https://console.cloud.google.com/functions) page in the Google Cloud Console.
   - Click **Create Function**.
2. **Configure the Function**:
   - **Function Name**: `delete-old-projects`
   - **Trigger**: HTTP
   - **Runtime**: Python 3.x
   - **Environment Variables**: Add `ORG_ID` with the value of your GCP organization ID.
   - **Service Account**: Select the service account created earlier.

3. **Upload Files**:
   - Upload the `main.py` and `requirements.txt` files.

4. **Deploy the Function**.

### Step 3: Set Up Cloud Scheduler
1. **Create a Scheduler Job**:
   - Navigate to the [Cloud Scheduler](https://console.cloud.google.com/cloudscheduler) page in the Google Cloud Console.
   - Click **Create Job**.

2. **Configure the Job**:
   - **Frequency**: Set the desired schedule (e.g., daily).
   - **Target**: HTTP
   - **URL**: Use the URL of the deployed Cloud Function.
   - **Authorization**: Use the Scheduler service account with the `roles/cloudfunctions.invoker` role.

---

## How the Function Works
1. The function retrieves all active projects within the specified organization using the Resource Manager API.
2. Filters projects based on the `created-by: terraform` label.
3. Calculates the age of each project.
4. Deletes projects older than 30 days using the Project Deletion API.

---

## Outputs
1. **Logging**:
   - Logs the IDs, names, creation dates, and ages of projects.
   - Logs successful or failed deletion attempts.

2. **HTTP Response**:
   - Returns a 200 status code with the message "Operation completed".

---

## Notes
1. Ensure the environment variable `ORG_ID` is correctly set during deployment.
2. The Cloud Scheduler and Cloud Function should use separate service accounts for better security.
3. Regularly review the logs in Cloud Logging for auditing purposes.

---

## Example Logs
```
INFO: Fetching projects in folder: folders/123456789012
INFO: Project ID: example-project-1, Name: Example Project 1, Created: 2023-11-15 12:34:56+00:00, Age: 32 days
INFO: Deleting project: example-project-1
INFO: Successfully deleted project: example-project-1
INFO: Operation completed.
```

For further assistance, contact 66Degrees Evolve team or raise a new ticket

