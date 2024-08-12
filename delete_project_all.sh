#!/bin/bash
set -ex

for project_id in $(curl --header "PRIVATE-TOKEN: glpat-wTscsa5Y6VrMVHDA7DsP" "http://35.75.155.254/gitlab/api/v4/projects?simple=true&per_page=100" | jq -r '.[].id'); do
  if [ "$project_id" == "125" ]; then # project_create
    echo "Skipping project with ID: $project_id"
    continue
  fi

  if [ "$project_id" == "126" ]; then #  project_create_mirror
    echo "Skipping project with ID: $project_id"
    continue
  fi

  echo "Deleting project with ID: $project_id"
  curl --request DELETE --header "PRIVATE-TOKEN: glpat-wTscsa5Y6VrMVHDA7DsP" "http://35.75.155.254/gitlab/api/v4/projects/${project_id}"
done
sleep 1
