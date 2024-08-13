#!/bin/bash
set -ex

# GitLabのURLとパーソナルアクセストークン
# GITLAB_URL="http://35.75.155.254/gitlab/api/v4" # ★ここは環境で変わるよ
# TOKEN="glpat-wTscsa5Y6VrMVHDA7DsP" # ★ここは環境で変わるよ
# SSMの設定が必要
GITLAB_URL="http://${gitlab_url}/gitlab/api/v4"
TOKEN=${gitlab_access_token}
NAMESPACE_ID="122"  # hello ネームスペースIDを指定  ★ここは環境で変わるよ

# プロジェクトとブランチのリストファイル
FILE="projects_and_branches.txt"

# ファイルを読み込み、各プロジェクトとブランチを作成
while IFS=: read -r project branches; do
  # プロジェクトを作成
  response=$(curl --silent --header "PRIVATE-TOKEN: $TOKEN" \
            --data "name=$project&namespace_id=$NAMESPACE_ID&visibility=public" \
            "$GITLAB_URL/projects")
  
  # プロジェクトIDを取得
  project_id=$(echo $response | jq -r '.id')

  if [[ "$project_id" == "null" ]]; then
    echo "Error creating project: $project"
    echo "Response: $response"
    continue
  fi
  
  echo "Created public project: $project (ID: $project_id)"
  
  # 1秒待機
  sleep 1

  # READMEファイルを追加
  readme_content="# $project"
  curl --silent --request POST --header "PRIVATE-TOKEN: $TOKEN" \
  --data "branch=main&start_branch=main&commit_message=Add README&actions[][action]=create&actions[][file_path]=README.md&actions[][content]=$readme_content" \
  "$GITLAB_URL/projects/$project_id/repository/commits"
  
  echo "Added README to main branch in project: $project"
  
  # 1秒待機
  sleep 1

  # ブランチを作成
  IFS=',' read -ra branch_list <<< "$branches"
  for branch in "${branch_list[@]}"; do
    # ブランチ作成
    curl --silent --request POST --header "PRIVATE-TOKEN: $TOKEN" \
    --data "branch=$branch&ref=main" \
    "$GITLAB_URL/projects/$project_id/repository/branches"
    
    echo "Created branch: $branch in project: $project"
    
    # 1秒待機
    sleep 1
  done
done < "$FILE"
