#!/bin/bash -e

actor=$1
admin_only=$2
workspace=$3
image_path=$4

echo "github.actor: ${actor}"
echo "admin-only: ${admin_only}"
if [[ ${admin_only} == true ]]; then
    echo "Expanding team mentions in the CODEOWNERS file"
    teams=$(grep -oE '@[[:alnum:]_.-]+\/[[:alnum:]_.-]+' ${workspace}/CODEOWNERS || true | sort | uniq)

    for team in $teams; do
    org=$(echo $team | cut -d'/' -f1 | sed 's/@//')
    team_name=$(echo $team | cut -d'/' -f2)
    members=$(gh api "/orgs/$org/teams/$team_name/members" | jq -r '.[].login')
    replacement=$(echo "$members" | xargs -I {} echo -n "@{} " | awk '{$1=$1};1')
    sed -i "s|$team|$replacement|g" ${workspace}/CODEOWNERS
    done

    if grep -wq "@${actor}" ${workspace}/CODEOWNERS; then
    echo "The workflow is triggered by ${actor} as the code owner"
    elif cat ${workspace}/${{ inputs.image-path }}/contacts.yaml | yq ".maintainers" | grep -wq "${actor}"; then
    echo "The workflow is triggered by ${actor} as a maintainer of the image ${{ inputs.image-path }}"
    else
    echo "The workflow is triggered by a user neither as a code owner nor a maintainer of the image ${{ inputs.image-path }}"
    exit 1
    fi
else
    echo "The workflow is not restricted to non-code-owner or non-maintainer users"
fi
