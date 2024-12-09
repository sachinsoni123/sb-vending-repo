#!/bin/bash

# Variables
TOKEN=$GITHUB_TOKEN  # Use the GitHub token from environment variables
OWNER="sachinsoni123"  # Your GitHub username or organization
REPO="sb-vending-repo"  # Repository name
BRANCH="main"  # Branch to delete the file from
# Array of specific file paths to delete
DISABLED_PROJECTS_FILE="disabled_projects.txt"

# Base directories for file paths
BASE_PATHS=("gp-vending/data" "sandbox-vending/data")  # Directories where files are located
FILE_PATTERN="*.tmpl.json"  # File pattern for deletion

# Fetch disabled projects
fetch_disabled_projects() {
    echo "Fetching disabled projects..."
    gcloud projects list --filter="lifecycleState=DELETE_REQUESTED OR lifecycleState=DELETED" \
        --format="value(projectId)" > "$DISABLED_PROJECTS_FILE"
    echo "Disabled projects saved to $DISABLED_PROJECTS_FILE"
}

# Fetch the file's SHA
get_file_sha() {
    local file_path=$1
    echo "Fetching SHA for $file_path..."
    RESPONSE=$(curl -s -H "Authorization: token $TOKEN" \
        "https://api.github.com/repos/$OWNER/$REPO/contents/$file_path?ref=$BRANCH")

    echo "Response from SHA fetch: $RESPONSE"  # Debugging line

    SHA=$(echo "$RESPONSE" | jq -r '.sha')
    if [[ "$SHA" == "null" || -z "$SHA" ]]; then
        echo "File $file_path not found in branch $BRANCH."
        return 1
    fi
    echo "SHA for $file_path: $SHA"
    echo "$SHA"
}

# Delete the file
delete_file() {
    local file_path=$1
    local sha=$2
    echo "Deleting $file_path from branch $BRANCH..."
    
    # Properly escape the payload
    PAYLOAD=$(cat <<EOF
{
  "message": "Delete $file_path",
  "sha": "$sha",
  "branch": "$BRANCH"
}
EOF
)

    echo "Payload: $PAYLOAD"  # Debugging line

    RESPONSE=$(curl -s -X DELETE -H "Authorization: token $TOKEN" \
        -H "Content-Type: application/json" \
        -d "$PAYLOAD" \
        "https://api.github.com/repos/$OWNER/$REPO/contents/$file_path")

    echo "Response from delete: $RESPONSE"  # Debugging line

    if [[ "$(echo "$RESPONSE" | jq -r '.commit.sha')" != "null" && "$(echo "$RESPONSE" | jq -r '.commit.sha')" != "" ]]; then
        echo "File $file_path successfully deleted."
    else
        echo "Failed to delete $file_path. Response: $RESPONSE"
        return 1
    fi
}

# Main execution
main() {
    # Fetch disabled projects
    fetch_disabled_projects

    if [[ ! -s $DISABLED_PROJECTS_FILE ]]; then
        echo "No disabled projects found. Exiting."
        exit 0
    fi

    # Iterate over each disabled project
    while read -r project_id; do
        echo "Processing project: $project_id"
        
        # Iterate over each base path and check for .tmpl.json files
        for base_path in "${BASE_PATHS[@]}"; do
            # Form the correct file path based on the project ID
            if [[ "$base_path" == "gp-vending/data" ]]; then
                full_path="gp-vending/data/$project_id.tmpl.json"  # Correct path for gp-vending
            elif [[ "$base_path" == "sandbox-vending/data" ]]; then
                full_path="sandbox-vending/data/$project_id.tmpl.json"  # Correct path for sandbox-vending
            fi

            echo "Looking for file: $full_path"
            
            # Check if the file exists on GitHub
            sha=$(get_file_sha "$full_path")
            if [[ $? -eq 0 ]]; then
                delete_file "$full_path" "$sha"
            else
                echo "Skipping deletion for $full_path due to missing SHA."
            fi
        done
    done < "$DISABLED_PROJECTS_FILE"
}

# Run the script
main
