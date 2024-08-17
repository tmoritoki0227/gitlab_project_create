# GitLabのURLとパーソナルアクセストークン
$GitLabUrl = "http://35.75.155.254/gitlab/api/v4" # 環境により変更
$Token = "glpat-wTscsa5Y6VrMVHDA7DsP" # 環境により変更

# プロジェクトの一覧を取得し、特定のプロジェクトを除外して削除
$projects = Invoke-RestMethod -Uri "$GitLabUrl/projects?simple=true&per_page=100" -Headers @{ "PRIVATE-TOKEN" = $Token } -Method Get
foreach ($project in $projects) {
    $projectId = $project.id
    switch ($projectId) {
        "125" { # 特定のプロジェクトIDをスキップ
            Write-Host "Skipping project with ID: $projectId"
            continue
        }
        "126" { # 特定のプロジェクトIDをスキップ
            Write-Host "Skipping project with ID: $projectId"
            continue
        }
        default {
            Write-Host "Deleting project with ID: $projectId"
            Invoke-RestMethod -Uri "$GitLabUrl/projects/$projectId" -Headers @{ "PRIVATE-TOKEN" = $Token } -Method Delete
        }
    }
    Start-Sleep -Seconds 1
}
