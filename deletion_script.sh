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
                git rm "$file"
            fi
        done < disabled_projects.txt
    done
}

# Commit and push changes
commit_and_push_changes() {
    # Configure Git user identity
    git config --global user.name nagesh66  
    git config --global user.email nagesh.kumarsingh@66degrees.com

    if git diff --cached --quiet; then
        echo "No files to delete."
        return
    fi

    echo "Committing and pushing changes..."
    git commit -m "Delete JSON files for disabled projects"
    git push origin "$(git rev-parse --abbrev-ref HEAD):refs/heads/$(git rev-parse --abbrev-ref HEAD)"
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



#!/bin/bash

# Variables
GITHUB_CONTENTS_PATHS=("gp-vending/data" "sandbox-vending/data")
BRANCH_NAME="main"  # Change this if your default branch is not 'main'

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
                git rm "$file"
            fi
        done < disabled_projects.txt
    done
}

# Commit and push changes
commit_and_push_changes() {
    # Configure Git user identity
    git config --global user.name nagesh66  
    git config --global user.email nagesh.kumarsingh@66degrees.com

    
    git checkout main

    if git diff --cached --quiet; then
        echo "No files to delete."
        return
    fi

    echo "Committing and pushing changes..."
    git commit -m "Delete JSON files for disabled projects"
    git push origin main
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
