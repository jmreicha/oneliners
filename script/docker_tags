#!/bin/bash

set -eu

UNAME=""
UPASS=""
ORG=""
DOCKER_REPO=""
DOCKER_TAG=""

# Get the auth token
TOKEN=$(curl -s -H "Content-Type: application/json" -X POST -d '{"username": "'${UNAME}'", "password": "'${UPASS}'"}' https://hub.docker.com/v2/users/login/ | jq -r .token)

# List a single tag for a repo
list_tag() {
    echo "Listing tag $DOCKER_TAG for $DOCKER_REPO"
    repo_tag=$(curl -s -H "Authorization: JWT $TOKEN" "https://hub.docker.com/v2/repositories/${ORG}/${DOCKER_REPO}/tags/${DOCKER_TAG}/" | jq -r '.name')

    if [[ $repo_tag == "null" ]]; then
        echo "Tag doesn't exist"
        exit 1
    else
        echo "Tag is $repo_tag"
    fi
}

# List all tags for a repo
list_all_tags() {
    echo "Listing all tags for $DOCKER_REPO"
    curl -s -H "Authorization: JWT $TOKEN" "https://hub.docker.com/v2/repositories/${ORG}/${DOCKER_REPO}/tags/?page_size=1000" | jq -r '.results|.[]|.name'
}

# List all repositories
list_all_repos() {
    echo "Retrieving repository list ..."
    REPO_LIST=$(curl -s -H "Authorization: JWT ${TOKEN}" https://hub.docker.com/v2/repositories/${ORG}/?page_size=1000 | jq -r '.results|.[]|.name')
    echo "$REPO_LIST"
}

# Output all images & tags
list_all_repos_and_tags() {
    echo "Images and tags for organization: ${ORG}"

        for i in ${REPO_LIST}
        do
            echo "${i}:"
            # Get the tags
            IMAGE_TAGS=$(curl -s -H "Authorization: JWT ${TOKEN}" https://hub.docker.com/v2/repositories/${ORG}/"${i}"/tags/?page_size=10000 | jq -r '.results|.[]|.name')
            # List indivdual tag
            for j in ${IMAGE_TAGS}
            do
                echo "  - ${j}"
            done
        done
}

main() {
    #list_all_tags
    list_tag
    #list_all_repos
}

main
