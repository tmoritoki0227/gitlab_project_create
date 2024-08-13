require 'net/http'
require 'uri'
require 'json'

# GitLabのURLとパーソナルアクセストークン
GITLAB_URL = "http://35.75.155.254/gitlab/api/v4"
TOKEN = "glpat-wTscsa5Y6VrMVHDA7DsP"

# プロジェクトとブランチのリストファイル
FILE = 'projects_and_branches.txt'

# APIリクエストを送信するメソッド
def send_request(uri, token, data = nil, method = :post)
  uri = URI(uri)
  http = Net::HTTP.new(uri.host, uri.port)
  request = Net::HTTP::Post.new(uri.request_uri, { 'PRIVATE-TOKEN' => token })

  case method
  when :post
    request.body = URI.encode_www_form(data) if data
  when :get
    request = Net::HTTP::Get.new(uri.request_uri, { 'PRIVATE-TOKEN' => token })
  end

  response = http.request(request)

  unless response.code.to_i == 200
    puts "Error: Received HTTP #{response.code} for request to #{uri}"
    puts "Response: #{response.body}"
    exit(1)
  end

  JSON.parse(response.body)
end

# ファイルを読み込み、各プロジェクトとブランチを作成
File.readlines(FILE).each do |line|
  project, branches = line.strip.split(':')

  # プロジェクトを作成
  project_data = {
    'name' => project,
    'namespace_id' => ENV['NAMESPACE_ID'],
    'visibility' => 'public'
  }

  response = send_request("#{GITLAB_URL}/projects", TOKEN, project_data)
  project_id = response['id']

  if project_id.nil?
    puts "Error creating project: #{project}"
    puts "Response: #{response}"
    next
  end

  puts "Created public project: #{project} (ID: #{project_id})"

  # 1秒待機
  sleep 1

  # READMEファイルを追加
  readme_content = "# #{project}"
  commit_data = {
    'branch' => 'main',
    'start_branch' => 'main',
    'commit_message' => 'Add README',
    'actions' => [
      {
        'action' => 'create',
        'file_path' => 'README.md',
        'content' => readme_content
      }
    ]
  }

  send_request("#{GITLAB_URL}/projects/#{project_id}/repository/commits", TOKEN, commit_data)
  puts "Added README to main branch in project: #{project}"

  # 1秒待機
  sleep 1

  # ブランチを作成
  next if branches.nil? || branches.empty?

  branches.split(',').each do |branch|
    branch_data = {
      'branch' => branch,
      'ref' => 'main'
    }

    send_request("#{GITLAB_URL}/projects/#{project_id}/repository/branches", TOKEN, branch_data)
    puts "Created branch: #{branch} in project: #{project}"

    # 1秒待機
    sleep 1
  end
end
