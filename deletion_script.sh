#!/bin/bash
TOKEN=$GITHUB_TOKEN  # GitHub token from environment variables
OWNER="sachinsoni123"     # GitHub username or organization
REPO="sb-vending-repo"     # Repository name
BRANCH="main"        # Branch to delete the file from
GITHUB_DIRECTORIES=("sandbox-vending/data" "gp-vending/data")
DELETED_FILES=()     # Array to store names of deleted files

# Fetch disabled projects
fetch_disabled_projects() {
    echo "Fetching disabled projects..."
    gcloud projects list --filter="lifecycleState=DELETE_REQUESTED OR lifecycleState=DELETED" \
        --format="value(projectId)" > disabled_projects.txt
    echo "Disabled projects:"
    cat disabled_projects.txt
}

# Function to delete file from GitHub
delete_file_from_github() {
    local directory=$1
    local project_id=$2

    file_path="$directory/$project_id.tmpl.json"

    echo "Checking for file: $file_path"

    # Get file details from GitHub
    response=$(curl -s -H "Authorization: token $TOKEN" \
        "https://api.github.com/repos/$OWNER/$REPO/contents/$file_path?ref=$BRANCH")

    # Check if file exists
    sha=$(echo "$response" | jq -r .sha)

    if [[ "$sha" == "null" || -z "$sha" ]]; then
        echo "No file found for project: $project_id in directory: $directory"
    else
        echo "Found file: $file_path with SHA: $sha"

        # Delete the file from GitHub
        delete_response=$(curl -s -X DELETE -H "Authorization: token $TOKEN" \
            -d "{\"message\": \"Delete $file_path\", \"sha\": \"$sha\"}" \
            "https://api.github.com/repos/$OWNER/$REPO/contents/$file_path")

        echo "Delete response: $delete_response"

        # Add file to the deleted files list
        DELETED_FILES+=("$file_path")
    fi
}

# Main script execution
fetch_disabled_projects

if [[ ! -f disabled_projects.txt ]]; then
    echo "No disabled projects file found. Exiting."
    exit 1
fi

while IFS= read -r project_id; do
    for directory in "${GITHUB_DIRECTORIES[@]}"; do
        delete_file_from_github "$directory" "$project_id"
    done
done < disabled_projects.txt

# Final output
if [[ ${#DELETED_FILES[@]} -gt 0 ]]; then
    echo "File deletion process completed with the following files deleted:"
    for file in "${DELETED_FILES[@]}"; do
        echo "- $file"
    done
else
    echo "File deletion process completed. No files were deleted."
fi
