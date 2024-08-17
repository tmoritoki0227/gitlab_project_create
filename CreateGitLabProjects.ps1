# PowerShell Script to Create GitLab Projects and Branches

# GitLab URL and Personal Access Token
$GitLabUrl = "http://35.75.155.254/gitlab/api/v4"  # ★ここは環境で変わります
$Token = "glpat-wTscsa5Y6VrMVHDA7DsP"  # ★ここは環境で変わります

$NamespaceId = "122"  # hello ネームスペースIDを指定  ★ここは環境で変わります

# File containing project and branches list
$File = "projects_and_branches.txt"

# Read the file and create projects and branches
$Content = Get-Content $File

foreach ($Line in $Content) {
    $Line = $Line.Trim()

    if ($Line -eq "") {
        continue  # 空行をスキップ
    }

    # プロジェクト名とブランチリストを分割
    $Parts = $Line -split ":", 2
    $Project = $Parts[0].Trim()
    $Branches = $Parts[1].Trim()

    # Create the project
    $Response = Invoke-RestMethod -Uri "$GitLabUrl/projects" `
        -Method Post `
        -Headers @{ "PRIVATE-TOKEN" = $Token } `
        -Body @{
            name = $Project
            namespace_id = $NamespaceId
            visibility = "public"
        }

    $ProjectId = $Response.id

    if (-not $ProjectId) {
        Write-Host "Error creating project: $Project"
        Write-Host "Response: $Response"
        continue
    }

    Write-Host "Created public project: $Project (ID: $ProjectId)"
    
    # Wait for 1 second
    Start-Sleep -Seconds 1

    try {
        # Add README file
        $ReadmeContent = "# $Project"
        $CommitBody = @{
            branch = "main"
            commit_message = "Add README"
            actions = @(
                @{
                    action = "create"
                    file_path = "README.md"
                    content = $ReadmeContent
                }
            )
        }

        $CommitResponse = Invoke-RestMethod -Uri "$GitLabUrl/projects/$ProjectId/repository/commits" `
            -Method Post `
            -Headers @{ "PRIVATE-TOKEN" = $Token } `
            -Body ($CommitBody | ConvertTo-Json -Depth 3) `
            -ContentType "application/json"

        Write-Host "Added README to main branch in project: $Project"

        # Wait for 1 second
        Start-Sleep -Seconds 1

        # Create branches if specified
        if ($Branches -ne "") {
            $BranchList = $Branches.Split(",")
            foreach ($Branch in $BranchList) {
                try {
                    $BranchBody = @{
                        branch = $Branch
                        ref = "main"
                    }

                    $BranchResponse = Invoke-RestMethod -Uri "$GitLabUrl/projects/$ProjectId/repository/branches" `
                        -Method Post `
                        -Headers @{ "PRIVATE-TOKEN" = $Token } `
                        -Body ($BranchBody | ConvertTo-Json) `
                        -ContentType "application/json"

                    Write-Host "Created branch: $Branch in project: $Project"
                } catch {
                    Write-Host "Failed to create branch: $Branch in project: $Project"
                    Write-Host "Error: $_"
                }
            }
        } else {
            Write-Host "No branches specified for project: $Project"
        }
    } catch {
        Write-Host "An error occurred while creating README or branches in project: $Project"
        Write-Host "Error: $_"
    }
}
