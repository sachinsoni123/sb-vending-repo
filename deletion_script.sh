#!/bin/bash

# Variables
DISABLED_PROJECTS_FILE="disabled_projects.txt"
DIRS=("gp-vending/data" "sandbox-vending/data")
GCP_PROJECTS=$(gcloud projects list --filter="lifecycleState=DELETE_REQUESTED OR lifecycleState=DELETED" --format="value(projectId)")
GITHUB_TOKEN=$GITHUB_TOKEN
OWNER="sachinsoni123"
REPO="sb-vending-repo"
BRANCH="main"

# Function to fetch file SHA from GitHub
get_file_sha() {
    local file_path=$1
    echo "Fetching SHA for $file_path..."
    RESPONSE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
        "https://api.github.com/repos/$OWNER/$REPO/contents/$file_path?ref=$BRANCH")

    echo "GitHub API Response for SHA fetch: $RESPONSE"  # Debug: print response
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
    echo "SHA for deletion: $sha"  # Print the SHA

    # Properly escape the JSON payload (using jq for clarity)
    JSON_PAYLOAD=$(jq -n \
        --arg message "Delete $file_path" \
        --arg sha "$sha" \
        --arg branch "$BRANCH" \
        '{message: $message, sha: $sha, branch: $branch}')
    echo "JSON Payload: $JSON_PAYLOAD" # Print the JSON

    RESPONSE=$(curl -s -v -X DELETE -H "Authorization: token $GITHUB_TOKEN" \
              -H "Content-Type: application/json" \
              -d "$JSON_PAYLOAD" \
              "https://api.github.com/repos/$OWNER/$REPO/contents/$(python -c "import urllib.parse; print(urllib.parse.quote_plus('$file_path'))")") 


    echo "GitHub API Response for file deletion: $RESPONSE"  # Debug: print response

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
        files=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
            "https://api.github.com/repos/$OWNER/$REPO/contents/$dir?ref=$BRANCH" | jq -r '.[].name')

        for file in $files; do
            if [[ "$file" == *"$project_id"*".tmpl.json" ]]; then
                file_path="$dir/$file"
                echo "Processing file: $file_path"  # Debug: log the file being processed
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
    echo "$GCP_PROJECTS" > "$DISABLED_PROJECTS_FILE"
    echo "Disabled projects list saved to $DISABLED_PROJECTS_FILE"

    for project_id in $GCP_PROJECTS; do
        delete_project_files "$project_id"
    done

    echo "File deletion process completed."
}

main
