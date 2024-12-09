#!/bin/bash

# Variables
DISABLED_PROJECTS_FILE="disabled_projects.txt"  # File to store disabled project IDs
DIRS=("gp-vending/data" "sandbox-vending/data")  # Directories to check for project files
GCP_PROJECTS=$(gcloud projects list --filter="lifecycleState=DELETE_REQUESTED OR lifecycleState=DELETED" --format="value(projectId)")  # Get list of deleted projects
GITHUB_TOKEN=$GITHUB_TOKEN  # GitHub token
OWNER="sachinsoni123"  # Your GitHub username or organization
REPO="sb-vending-repo"  # Repository name
BRANCH="main"  # Branch where the files should be deleted from

# Function to fetch file SHA from GitHub
get_file_sha() {
    local file_path=$1
    echo "Fetching SHA for $file_path..."
    RESPONSE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
        "https://api.github.com/repos/$OWNER/$REPO/contents/$file_path?ref=$BRANCH")

    SHA=$(echo "$RESPONSE" | jq -r '.sha')
    if [[ "$SHA" == "null" ]]; then
        echo "File $file_path not found in branch $BRANCH."
        return 1
    fi
    echo "SHA for $file_path: $SHA"
    return 0
}

# Function to delete file from GitHub
delete_file() {
    local file_path=$1
    local sha=$2
    echo "Deleting $file_path from GitHub repository $REPO..."

    # Properly escape the JSON payload
    encoded_file_path=$(python -c "import urllib.parse; print(urllib.parse.quote_plus('$file_path'))")

      RESPONSE=$(curl -s -X DELETE -H "Authorization: token $GITHUB_TOKEN" \
                 -H "Content-Type: application/json" \
                 -d "{\"message\": \"Delete $file_path\", \"sha\": \"$sha\", \"branch\": \"$BRANCH\"}" \
                 "https://api.github.com/repos/$OWNER/$REPO/contents/$encoded_file_path")

    if [[ "$(echo "$RESPONSE" | jq -r '.commit.sha')" != "null" ]]; then
        echo "File $file_path successfully deleted."
    else
        echo "Failed to delete $file_path. Response: $RESPONSE"
    fi
}

# Function to delete project-related files from GitHub
delete_project_files() {
    local project_id=$1  # Project ID passed as argument
    echo "Deleting files related to project: $project_id"

    for dir in "${DIRS[@]}"; do
        # Construct the file path for the directory
        file_path="$dir/*$project_id*.tmpl.json"

        # Fetch and delete files that match the pattern
        files_to_delete=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
            "https://api.github.com/repos/$OWNER/$REPO/contents/$dir?ref=$BRANCH" | jq -r '.[] | select(.name | test("'"$project_id"'")) | .path')

        for file in $files_to_delete; do
            sha=$(get_file_sha "$file")
            if [[ $? -eq 0 ]]; then
                delete_file "$file" "$sha"
            fi
        done
    done
}

# Main execution
main() {
    # Save the list of disabled projects to the file
    echo "$GCP_PROJECTS" > "$DISABLED_PROJECTS_FILE"
    echo "Disabled projects list saved to $DISABLED_PROJECTS_FILE"

    # Read project IDs into an array
      readarray -t PROJECT_IDS <<< "$GCP_PROJECTS"

      # Iterate over the array
      for project_id in "${PROJECT_IDS[@]}"; do
          delete_project_files "$project_id"
      done


    echo "File deletion process completed."
}

# Run the script
main
