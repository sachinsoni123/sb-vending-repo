#!/bin/bash



# Variables

GITHUB_TOKEN=$GITHUB_TOKEN

GITHUB_OWNER="sachinsoni123"

GITHUB_REPO="sb-vending-repo"

GITHUB_BRANCH="main" # Change this to your target branch

GITHUB_CONTENTS_PATHS=("gp-vending/data" "sandbox-vending/data")



# Fetch disabled projects from Google Cloud

fetch_disabled_projects() {

    echo "Fetching disabled projects..."

    gcloud projects list --filter="lifecycleState=DELETE_REQUESTED OR lifecycleState=DELETED" --format="value(projectId)" > disabled_projects.txt

}



# Delete files using SHA method via GitHub API

delete_matching_files() {

    echo "Deleting files matching disabled projects..."

    for path in "${GITHUB_CONTENTS_PATHS[@]}"; do

        echo "Checking path: $path"

        while IFS= read -r project_id; do

            file="${path}/${project_id}.tmpl.json"

            api_url="https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/contents/${file}"

            

            echo "Fetching SHA for: $file"

            sha=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" "${api_url}" | jq -r '.sha')

            

            if [[ "$sha" != "null" ]]; then

                echo "Deleting file: $file"

                curl -s -X DELETE -H "Authorization: token ${GITHUB_TOKEN}" \

                    -H "Content-Type: application/json" \

                    -d "$(jq -n --arg message "Delete JSON file for disabled project $project_id" \

                             --arg branch "${GITHUB_BRANCH}" --arg sha "${sha}" \

                             '{message: $message, branch: $branch, sha: $sha}')" \

                    "${api_url}"

                echo "File deleted: $file"

            else

                echo "File not found: $file"

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
