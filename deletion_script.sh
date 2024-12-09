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
    echo "$SHA"
    return 0
}

# Function to delete file from GitHub
delete_file() {
    local file_path=$1
    local sha=$2
    echo "Deleting $file_path from GitHub repository $REPO..."

    RESPONSE=$(curl -s -X DELETE \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"message\": \"Delete $file_path\", \"sha\": \"$sha\", \"branch\": \"$BRANCH\"}" \
        "https://api.github.com/repos/$OWNER/$REPO/contents/$file_path")

    if [[ "$(echo "$RESPONSE" | jq -r '.commit.sha')" != "null" ]]; then
        echo "File $file_path successfully deleted."
    else
        echo "Failed to delete $file_path. Response: $RESPONSE"
    fi
}

# Function to delete project-related files from GitHub
delete_project_files() {
    local project_id=$1
    echo "Deleting files related to project: $project_id"

    for dir in "${DIRS[@]}"; do
        # List all files in the directory from GitHub
        files=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
            "https://api.github.com/repos/$OWNER/$REPO/contents/$dir?ref=$BRANCH" | jq -r '.[].name')

        # Filter files matching the project ID and process them
        for file in $files; do
            if [[ "$file" == *"$project_id"*".tmpl.json" ]]; then
                file_path="$dir/$file"
                sha=$(get_file_sha "$file_path")
                if [[ $? -eq 0 ]]; then
                    delete_file "$file_path" "$sha"
                fi
            fi
        done
    done
}

# Main execution
main() {
    # Save the list of disabled projects to the file
    echo "$GCP_PROJECTS" > "$DISABLED_PROJECTS_FILE"
    echo "Disabled projects list saved to $DISABLED_PROJECTS_FILE"

    # Iterate over each project ID and delete related files
    for project_id in $GCP_PROJECTS; do
        delete_project_files "$project_id"
    done

    echo "File deletion process completed."
}

# Run the script
main
