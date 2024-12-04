#!/bin/bash

# Variables
GITHUB_CONTENTS_PATH="path/to/json/files"

# Check disabled projects from Google Cloud
fetch_disabled_projects() {
    echo "Fetching disabled projects..."
    gcloud projects list --filter="lifecycleState=DELETE_REQUESTED OR lifecycleState=DELETED" \
        --format="value(projectId)" > disabled_projects.txt
}

# Delete files matching disabled projects
delete_matching_files() {
    echo "Deleting files matching disabled projects..."
    while IFS= read -r project_id; do
        file="${GITHUB_CONTENTS_PATH}/${project_id}.tmpl.json"
        if [[ -f "$file" ]]; then
            echo "Deleting file: $file"
            git rm "$file"
        fi
    done < disabled_projects.txt
}

# Commit and push changes
commit_and_push_changes() {
    if git diff --cached --quiet; then
        echo "No files to delete."
        return
    fi

    echo "Committing and pushing changes..."
    git commit -m "Delete JSON files for disabled projects"
    git push origin "$(git rev-parse --abbrev-ref HEAD)"
}

# Main script execution
main() {
    fetch_disabled_projects
    if [[ ! -s disabled_projects.txt ]]; then
        echo "No disabled projects found."
        exit 0
    fi

    delete_matching_files
    commit_and_push_changes
    echo "Cleanup completed."
}

main
