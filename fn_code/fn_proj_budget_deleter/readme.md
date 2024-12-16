# Cloud Function: Automatic Project Deletion Based on Budget Alert Threshold

## Overview
This Cloud Function is triggered by messages published to a Cloud Pub/Sub topic when a budget alert threshold is exceeded. Upon receiving a notification indicating that 100% of the budget has been utilized (threshold `1.0`), the function identifies the associated project and deletes it.

## Prerequisites
1. **Pub/Sub Topic**:
   - A Cloud Pub/Sub topic must be created in the project where this function is deployed.
   - Ensure the budget alert is configured to publish notifications to this Pub/Sub topic.
2. **Budget Alerts**:
   - A billing budget with an alert threshold configured for `100%` usage.
3. **Service Account Permissions**:
   - The service account running this function requires the following roles:
     - `roles/resourcemanager.projectDeleter` (to delete projects).
   
## Files
- **main.py**: Contains the function logic.
- **requirements.txt**: Lists dependencies for the function.

## Function Workflow
1. **Trigger**:
   - The function is triggered when a message is published to the Pub/Sub topic.
2. **Processing the Message**:
   - The function decodes and parses the Pub/Sub message.
   - Extracts the project ID from the budget alert notification.
   - Checks if the alert threshold is `1.0` (indicating 100% of the budget is used).
3. **Action**:
   - Deletes the project if the threshold condition is met.

## Deployment Steps

### 1. Set Up the Pub/Sub Topic
- Create a Cloud Pub/Sub topic in the Google Cloud project where the function will be deployed.
- Configure your billing budget to publish notifications to this topic.

### 2. Deploy the Cloud Function

#### Using the Google Cloud Console:
1. Navigate to the Cloud Functions page.
2. Click **Create Function**.
3. Fill out the following details:
   - **Name**: Provide a name for the function (e.g., `delete-project-on-budget`).
   - **Trigger**: Select **Pub/Sub** and choose the topic created earlier.
   - **Runtime**: Choose Python 3.11 or compatible version.
4. Upload the `main.py` and `requirements.txt` files.
5. Set the environment variable `PROJECT_ID` with the project ID where the Pub/Sub topic resides.
6. Assign the service account to the function with the required permissions.
7. Deploy the function.

#### Using the gcloud CLI:
```bash
# Deploy the function
gcloud functions deploy delete_project_on_budget \
  --runtime python311 \
  --trigger-topic <YOUR_PUBSUB_TOPIC_NAME> \
  --source . \
  --entry-point hello_pubsub \
  --region <REGION> \
  --service-account <SERVICE_ACCOUNT_EMAIL>
```

### 3. Assign Required IAM Roles
- Assign the `roles/resourcemanager.projectDeleter` role to the service account associated with the Cloud Function.

### 4. Test the Function
- Publish a test message to the Pub/Sub topic to simulate a budget alert notification.
```bash
# Publish a test message to the Pub/Sub topic
MESSAGE='{"budgetDisplayName": "Billing budget/<PROJECT_ID>", "alertThresholdExceeded": 1.0}'
echo "$MESSAGE" | gcloud pubsub topics publish <YOUR_TOPIC_NAME> --message "$MESSAGE"
```

## Permissions Required
- **Cloud Pub/Sub**:
  - The service account running this function must have the `roles/pubsub.subscriber` role for the Pub/Sub topic.
- **Project Deletion**:
  - The service account must have the `roles/resourcemanager.projectDeleter` role to delete projects.

## Example Usage
- When the budget alert threshold exceeds `1.0`:
  - The function automatically deletes the associated project.

## Notes
- Ensure billing alerts and thresholds are properly configured.
- Deleting projects is a destructive operation. Use with caution and ensure proper auditing mechanisms are in place.

## Dependencies
Dependencies are listed in `requirements.txt`:
```txt
google-cloud-pubsub
google-cloud-resource-manager==1.13.0
google-cloud-logging==3.11.3
```

