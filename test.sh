#!/bin/bash

# Variables
TOKEN=$GITHUB_TOKEN  # Use the GitHub token from environment variables
OWNER="sachinsoni123"  # Your GitHub username or organization
REPO="sb-vending-repo"  # Repository name
FILE_PATH="sandbox-vending/data/nagesh-sb.tmpl.json"  # Path to the file to delete
BRANCH="main"  # Branch to delete the file from

# Fetch the file's SHA
get_file_sha() {
    echo "Fetching SHA for $FILE_PATH..."
    RESPONSE=$(curl -s -H "Authorization: token $TOKEN" \
        "https://api.github.com/repos/$OWNER/$REPO/contents/$FILE_PATH?ref=$BRANCH")

    SHA=$(echo "$RESPONSE" | jq -r '.sha')
    if [[ "$SHA" == "null" ]]; then
        echo "File $FILE_PATH not found in branch $BRANCH."
        exit 1
    fi
    echo "SHA for $FILE_PATH: $SHA"
}

# Delete the file
delete_file() {
    echo "Deleting $FILE_PATH from branch $BRANCH..."
    RESPONSE=$(curl -s -X DELETE -H "Authorization: token $TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"message\": \"Delete $FILE_PATH\", \"sha\": \"$SHA\", \"branch\": \"$BRANCH\"}" \
        "https://api.github.com/repos/$OWNER/$REPO/contents/$FILE_PATH")

    if [[ "$(echo "$RESPONSE" | jq -r '.commit.sha')" != "null" ]]; then
        echo "File $FILE_PATH successfully deleted."
    else
        echo "Failed to delete $FILE_PATH. Response: $RESPONSE"
        exit 1
    fi
}

# Main execution
main() {
    get_file_sha
    delete_file
}

# Run the script
main
