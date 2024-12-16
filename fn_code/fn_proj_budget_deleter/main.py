import base64
import logging
import json
from google.cloud import pubsub_v1
from google.cloud import resourcemanager_v3


def hello_pubsub(event, context):
   """Triggered from a message on a Cloud Pub/Sub topic.
   Args:
        event (dict): Event payload.
        context (google.cloud.functions.Context): Metadata for the event.
   """
   pubsub_message = base64.b64decode(event['data']).decode('utf-8')
   decoded_message = json.loads(pubsub_message)
   print(pubsub_message)
   try:       
       # Extract required fields
       budget_display_name = decoded_message.get('budgetDisplayName')
       alert_threshold_exceeded = decoded_message.get('alertThresholdExceeded')
       if budget_display_name.startswith("Billing budget/"):
           budget_display_name = budget_display_name[len("Billing budget/"):]
           project_id = budget_display_name


       # Log or process extracted data
       print(f"Budget Display Name: {budget_display_name}")
       print(f"Alert Threshold Exceeded: {alert_threshold_exceeded}")


       if alert_threshold_exceeded == 1.0:
           print(project_id)
           # Disable the associated project
           delete_project(project_id)
      
       # Additional processing logic can be added here
      
   except Exception as e:
       print(f"Error processing message: {e}")






def delete_project(project_id):
    project_client = resourcemanager_v3.ProjectsClient()
    try:
        logging.info(f"Deleting project: {project_id}")
        project_client.delete_project(name=f"projects/{project_id}")
        logging.info(f"Successfully deleted project: {project_id}")
    except Exception as e:
        logging.error(f"Failed to delete project {project_id}: {e}")