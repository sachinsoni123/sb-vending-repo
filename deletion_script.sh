#!/bin/bash

# Variables
GITHUB_CONTENTS_PATHS=("gp-vending/data" "sandbox-vending/data")

# Fetch disabled projects from Google Cloud
fetch_disabled_projects() {
    echo "Fetching disabled projects..."
    gcloud projects list --filter="lifecycleState=DELETE_REQUESTED OR lifecycleState=DELETED" \
        --format="value(projectId)" > disabled_projects.txt
}

# Delete files matching disabled projects in all paths
delete_matching_files() {
    echo "Deleting files matching disabled projects..."
    for path in "${GITHUB_CONTENTS_PATHS[@]}"; do
        echo "Checking path: $path"
        while IFS= read -r project_id; do
            file="${path}/${project_id}.tmpl.json"
            if [[ -f "$file" ]]; then
                echo "Deleting file: $file"
                rm "$file" || { echo "Failed to delete $file"; exit 1; }
            fi
        done < disabled_projects.txt
    done
}

# Main script execution
main() {
    fetch_disabled_projects
    if [[ ! -s disabled_projects.txt ]]; then
        echo "No disabled projects found."
        exit 0
    fi

    delete_matching_files
    echo "Cleanup completed."
}

main
