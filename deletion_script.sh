#!/bin/bash

# Variables
GITHUB_REPO="sachinsoni123/sb-vending-repo"
GITHUB_BRANCH="main"
GITHUB_DIRECTORIES=("sandbox-vending/data" "gp-vending/data")
GITHUB_API_URL="https://api.github.com/repos/${GITHUB_REPO}/contents"

# Check if GITHUB_TOKEN is set
if [[ -z "$GITHUB_TOKEN" ]]; then
    echo "Error: GITHUB_TOKEN is not set. Please export your GitHub token as an environment variable."
    exit 1
fi

# Fetch disabled projects from Google Cloud
fetch_disabled_projects() {
    echo "Fetching disabled projects..."
    gcloud projects list --filter="lifecycleState=DELETE_REQUESTED OR lifecycleState=DELETED" \
        --format="value(projectId)" > disabled_projects.txt
}

# Fetch GitHub files in the specified directory
fetch_github_files() {
    local directory="$1"
    echo "Fetching GitHub files from directory: $directory"
    curl -s -H "Authorization: token ${GITHUB_TOKEN}" "${GITHUB_API_URL}/${directory}" | jq -r '.[] | @base64' > "github_files_${directory//\//_}.txt"
}

# Decode base64 content safely
decode_base64() {
    echo "$1" | base64 --decode
}

# Process files and delete matching ones
process_and_delete_files() {
    local directory="$1"
    local github_files="github_files_${directory//\//_}.txt"

    echo "Processing and deleting files in directory: $directory"
    while IFS= read -r encoded_file; do
        file=$(decode_base64 "$encoded_file")
        filename=$(echo "$file" | jq -r '.name')
        sha=$(echo "$file" | jq -r '.sha')
        filepath=$(echo "$file" | jq -r '.path')

        if [[ "$filename" == *.tmpl.json ]]; then
            project_id="${filename%.tmpl.json}"
            if grep -q "$project_id" disabled_projects.txt; then
                echo "Deleting file: $filename"
                curl -s -X DELETE \
                    -H "Authorization: token ${GITHUB_TOKEN}" \
                    -d "$(jq -n --arg message "Deleting disabled project JSON file: $filename" \
                             --arg branch "$GITHUB_BRANCH" --arg sha "$sha" \
                             '{message: $message, branch: $branch, sha: $sha}')" \
                    "${GITHUB_API_URL}/${filepath}"
            fi
        fi
    done < "$github_files"
}

# Main script execution
main() {
    fetch_disabled_projects
    if [[ ! -s disabled_projects.txt ]]; then
        echo "No disabled projects found."
        exit 0
    fi

    for directory in "${GITHUB_DIRECTORIES[@]}"; do
        fetch_github_files "$directory"
        github_files="github_files_${directory//\//_}.txt"
        if [[ ! -s "$github_files" ]]; then
            echo "No files found in the GitHub repository path: $directory"
            continue
        fi
        process_and_delete_files "$directory"
    done

    echo "Cleanup completed."
}

main
