#!/bin/bash

# Variables
TOKEN=$GITHUB_TOKEN  # Use the GitHub token from environment variables
OWNER="sachinsoni123"  # Your GitHub username or organization
REPO="sb-vending-repo"  # Repository name
BRANCH="main"  # Branch to delete files from
DIRECTORIES=("gp-vending/data" "sandbox-vending/data")  # Target directories
PATTERN="*.tmpl.json"  # File pattern to match
DISABLED_PROJECTS_FILE="./disabled_projects.txt"  # File to store disabled projects

# Fetch list of disabled projects and save to file
fetch_disabled_projects() {
    echo "Fetching list of disabled projects..."
    gcloud projects list --filter="lifecycleState:DELETE_REQUESTED OR lifecycleState:DISABLED" \
        --format="value(projectId)" > "$DISABLED_PROJECTS_FILE"
    
    if [[ ! -s "$DISABLED_PROJECTS_FILE" ]]; then
        echo "No disabled projects found. Exiting."
        exit 0
    fi
    echo "Disabled projects saved to $DISABLED_PROJECTS_FILE."
}

# Fetch file SHA
get_file_sha() {
    local file_path=$1
    echo "Fetching SHA for $file_path..."
    RESPONSE=$(curl -s -H "Authorization: token $TOKEN" \
        "https://api.github.com/repos/$OWNER/$REPO/contents/$file_path?ref=$BRANCH")

    SHA=$(echo "$RESPONSE" | jq -r '.sha')
    if [[ "$SHA" == "null" ]]; then
        echo "File $file_path not found in branch $BRANCH."
        return 1
    fi
    echo "SHA for $file_path: $SHA"
    echo "$SHA"
}

# Delete file
delete_file() {
    local file_path=$1
    local sha=$2
    echo "Deleting $file_path from branch $BRANCH..."
    RESPONSE=$(curl -s -X DELETE -H "Authorization: token $TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"message\": \"Delete $file_path\", \"sha\": \"$sha\", \"branch\": \"$BRANCH\"}" \
        "https://api.github.com/repos/$OWNER/$REPO/contents/$file_path")

    if [[ "$(echo "$RESPONSE" | jq -r '.commit.sha')" != "null" ]]; then
        echo "File $file_path successfully deleted."
    else
        echo "Failed to delete $file_path. Response: $RESPONSE"
        exit 1
    fi
}

# Main execution
main() {
    fetch_disabled_projects

    echo "Processing directories..."
    for dir in "${DIRECTORIES[@]}"; do
        echo "Checking directory: $dir"
        RESPONSE=$(curl -s -H "Authorization: token $TOKEN" \
            "https://api.github.com/repos/$OWNER/$REPO/contents/$dir?ref=$BRANCH")

        FILES=$(echo "$RESPONSE" | jq -r '.[].name' | grep "$PATTERN")

        for file in $FILES; do
            PROJECT_NAME=$(echo "$file" | cut -d. -f1)  # Extract project name from filename
            if grep -qx "$PROJECT_NAME" "$DISABLED_PROJECTS_FILE"; then
                FILE_PATH="$dir/$file"
                SHA=$(get_file_sha "$FILE_PATH")
                if [[ -n "$SHA" ]]; then
                    delete_file "$FILE_PATH" "$SHA"
                fi
            else
                echo "Skipping $file (project is active or not found in disabled projects)."
            fi
        done
    done
}

# Run the script
main
