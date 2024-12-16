from google.cloud import resourcemanager_v3
from google.cloud.billing import budgets_v1beta1
import logging
from datetime import datetime, timezone, timedelta
import os

logging.basicConfig(level=logging.INFO)

def delete_project(project_id):
    project_client = resourcemanager_v3.ProjectsClient()
    try:
        logging.info(f"Deleting project: {project_id}")
        project_client.delete_project(name=f"projects/{project_id}")
        logging.info(f"Successfully deleted project: {project_id}")
    except Exception as e:
        logging.error(f"Failed to delete project {project_id}: {e}")


def list_projects_in_organization(org_id):
    """Lists all projects in the specified organization"""
    # Initialize clients
    project_client = resourcemanager_v3.ProjectsClient()
    folder_client = resourcemanager_v3.FoldersClient()

    def get_projects_in_folder(folder_name):
        """Recursively fetch all active projects under a folder."""
        projects = []
        logging.info(f"Fetching projects in folder: {folder_name}")

        # Fetch all projects under this folder
        for project in project_client.search_projects(request={"query": f"parent={folder_name}"}):
            if project.state == resourcemanager_v3.Project.State.ACTIVE:  # Check if project is active
                if project.labels.get("created-by") == "terraform":
                    create_time = datetime.fromtimestamp(project.create_time.timestamp(), tz=timezone.utc)
                    current_date = datetime.now(tz=timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)

                    # Calculate project age
                    age_days = (current_date - create_time).days
                    age_days = max(age_days, 0)  # Ensure no negative age

                    projects.append({
                        "project_id": project.project_id,
                        "project_name": project.display_name,
                        "create_time": create_time,
                        "age_days": age_days,
                    })

        # Fetch subfolders and process them recursively
        for subfolder in folder_client.search_folders(request={"query": f"parent={folder_name}"}):
            projects.extend(get_projects_in_folder(subfolder.name))
        
        return projects

    # Start from the organization level
    organization_name = f"organizations/{org_id}"
    projects_in_org = []

    logging.info(f"Starting search in organization: {organization_name}")
    for folder in folder_client.search_folders(request={"query": f"parent={organization_name}"}):
        projects_in_org.extend(get_projects_in_folder(folder.name))

    # Also check for projects directly under the organization
    for project in project_client.search_projects(request={"query": f"parent={organization_name}"}):
        if project.state == resourcemanager_v3.Project.State.ACTIVE:  # Check if project is active
            if project.labels.get("created-by") == "terraform":
                create_time = datetime.fromtimestamp(project.create_time.timestamp(), tz=timezone.utc)
                current_date = datetime.now(tz=timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)

                # Calculate project age
                age_days = (current_date - create_time).days
                age_days = max(age_days, 0)  # Ensure no negative age

                projects_in_org.append({
                    "project_id": project.project_id,
                    "project_name": project.display_name,
                    "create_time": create_time,
                    "age_days": age_days,
                })

    return projects_in_org

def main_entry(request):
    ORG_ID = os.environ.get('ORG_ID')


    # Fetch projects from the organization
    projects = list_projects_in_organization(ORG_ID)

    if projects:
        logging.info(f"Found {len(projects)} active projects with label 'created-by: terraform':")
        for project in projects:
            logging.info(f"Project ID: {project['project_id']}, Name: {project['project_name']}, "
                         f"Created: {project['create_time']}, Age: {project['age_days']} days")


            if project['age_days'] > 30:
                delete_project(project['project_id'])
                
    else:
        logging.info("No active projects with label 'created-by: terraform' found.")

    return "Operation completed", 200
