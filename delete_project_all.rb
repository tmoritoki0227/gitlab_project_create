# lambda_function.rb に張り付けてね
require 'net/http'
require 'uri'
require 'json'

# GitLabのURLとパーソナルアクセストークン
GITLAB_URL = ENV['GITLAB_URL'] || "http://35.75.155.254/gitlab/api/v4"
TOKEN = ENV['TOKEN'] || "glpat-wTscsa5Y6VrMVHDA7DsP"

# Lambdaハンドラ
def lambda_handler(event:, context:)
  # プロジェクトのリストを取得
  projects = get_projects

  projects.each do |project|
    project_id = project['id'].to_s

    if project_id == "125" || project_id == "126"
      puts "Skipping project with ID: #{project_id}"
      next
    end

    puts "Deleting project with ID: #{project_id}"
    delete_project(project_id)
  end

  sleep 1 # 1秒待機

  { statusCode: 200, body: JSON.generate("Projects processed successfully.") }
end

def get_projects
  uri = URI("#{GITLAB_URL}/projects?simple=true&per_page=100")
  request = Net::HTTP::Get.new(uri, { 'PRIVATE-TOKEN' => TOKEN })
  
  response = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(request)
  end

  if response.code.to_i != 200
    puts "Error: Received HTTP #{response.code} for request to #{uri}"
    puts "Response: #{response.body}"
    raise "Failed to retrieve projects"
  end

  JSON.parse(response.body)
end

def delete_project(project_id)
  uri = URI("#{GITLAB_URL}/projects/#{project_id}")
  request = Net::HTTP::Delete.new(uri, { 'PRIVATE-TOKEN' => TOKEN })

  response = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(request)
  end

  if response.code.to_i != 202
    puts "Error: Received HTTP #{response.code} for DELETE request to #{uri}"
    puts "Response: #{response.body}"
    raise "Failed to delete project with ID #{project_id}"
  end

  puts "Deleted project with ID: #{project_id}"
end
