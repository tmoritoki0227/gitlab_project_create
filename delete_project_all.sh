#!/bin/bash
set -ex

GITLAB_URL="http://35.75.155.254/gitlab/api/v4" # ★ここは環境で変わるよ
TOKEN="glpat-wTscsa5Y6VrMVHDA7DsP" # ★ここは環境で変わるよ
# SSMの設定が必要
# GITLAB_URL="http://${gitlab_url}/gitlab/api/v4"
# TOKEN=${gitlab_access_token}

# per_page=100の意味がわかってない。リポジトリが１００までしか取得できないとか？
for project_id in $(curl --silent --header "PRIVATE-TOKEN: $TOKEN" "${GITLAB_URL}/projects?simple=true&per_page=100" | jq -r '.[].id'); do
  if [ "$project_id" == "125" ]; then # project_create
    echo "Skipping project with ID: $project_id"
    continue
  fi

  if [ "$project_id" == "126" ]; then #  project_create_mirror
    echo "Skipping project with ID: $project_id"
    continue
  fi

  echo "Deleting project with ID: $project_id"
  curl --silent --request DELETE --header "PRIVATE-TOKEN: $TOKEN" "${GITLAB_URL}/projects/${project_id}"
done
sleep 1
