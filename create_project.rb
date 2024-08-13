# lambda_function.rb に張り付けてね
require 'net/http'
require 'uri'
require 'json'

# GitLabのURLとパーソナルアクセストークン
GITLAB_URL = ENV['GITLAB_URL'] || "http://35.75.155.254/gitlab/api/v4"
TOKEN = ENV['TOKEN'] || "glpat-wTscsa5Y6VrMVHDA7DsP"
NAMESPACE_ID = ENV['NAMESPACE_ID'] || "122" # デフォルトで"122"を使用

# Lambdaハンドラ
def lambda_handler(event:, context:)
  # プロジェクトとブランチのリストファイルを読み込む
  file_path = '/var/task/projects_and_branches.txt'
  
  unless File.exist?(file_path)
    return { statusCode: 500, body: JSON.generate("Error: File projects_and_branches.txt not found") }
  end

  projects_and_branches = File.readlines(file_path)

  projects_and_branches.each do |line|
    project, branches = line.strip.split(':')

    # プロジェクトを作成
    project_data = {
      'name' => project,
      'namespace_id' => NAMESPACE_ID,
      'visibility' => 'public'
    }

    begin
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
      unless branches.nil? || branches.empty?
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
    rescue => e
      puts "An error occurred: #{e.message}"
    end
  end

  { statusCode: 200, body: JSON.generate("Projects and branches processed successfully.") }
end

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
    raise "Request failed with response code #{response.code}"
  end

  JSON.parse(response.body)
end
