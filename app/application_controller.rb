# https://github.com/aprietof/Expensy
require 'json'
require 'aws-sdk-iam'
require 'octokit'

class ApplicationController < Sinatra::Base
  register Sinatra::ActiveRecordExtension

  before do
    content_type :json
  end

  post '/groups' do
    payload = JSON.parse(request.body.read).symbolize_keys
    group = Group.create!(
      name: payload[:name],
      github_group: payload[:github_group],
      metabase_group: payload[:metabase_group],
      sentry_group: payload[:sentry_group],
      aws_iam_role: payload[:aws_iam],
      slack_channels: payload[:slack_channels].split(",").map(&:strip).join(",").downcase,
      google_groups: payload[:google_groups].split(",").map(&:strip).join(",").downcase,
      staging_databases: payload[:staging_databases].split(",").map(&:strip).join(",").downcase,
      production_databases: payload[:production_databases].split(",").map(&:strip).join(",").downcase
    )
    group.to_json
  end

  put '/groups/:id' do
    payload = JSON.parse(request.body.read).symbolize_keys
    group = Group.find!(params[:id])
    group = group.update!(
      name: payload[:name],
      github_group: payload[:github_group],
      metabase_group: payload[:metabase_group],
      sentry_group: payload[:sentry_group],
      aws_iam_role: payload[:aws_iam],
      slack_channels: payload[:slack_channels].split(",").map(&:strip).join(",").downcase,
      google_groups: payload[:google_groups].split(",").map(&:strip).join(",").downcase,
      staging_databases: payload[:staging_databases].split(",").map(&:strip).join(",").downcase,
      production_databases: payload[:production_databases].split(",").map(&:strip).join(",").downcase
    )
    group = Group.find(params[:id])
    group.to_json
  end

  post '/databases' do
    payload = JSON.parse(request.body.read).map(&:symbolize_keys)
    credentials = []
    DatabaseCredential.delete_all
    payload.each do |row|
      credentials << DatabaseCredential.create!(
        db_host: row[:host],
        db_port: row[:port],
        db_name: row[:name],
        db_user: row[:user],
        db_password: row[:password],
        db_env: row[:env],
        allowed_databases: row[:allowed_databases],
      )
    end
    credentials.to_json
  end

  post '/groups/:id/users/onboard' do
    payload = JSON.parse(request.body.read).symbolize_keys
    group = Group.find(params[:id])
    user = User.create!(
      email: payload[:email].downcase,
      github_user: payload[:github_user].downcase,
      ssh_key: payload[:ssh_key],
      group_id: params[:id]
    )
    config = payload[:config].symbolize_keys
    password = SecureRandom.alphanumeric(12)
    create_aws_user(user.email, group.aws_iam_role, password) if(config[:aws])
    create_github_user(group.github_group, user.github_user) if(config[:github])
    create_datadog_user(user.email) if(config[:datadog])
    create_metabase_user(user.email, password, group.metabase_group) if(config[:metabase])
    create_db_users_on_staging(group.staging_databases, user.email, password) if(config[:staging_databases])
    { email: user.email, password: password, group: group.name }.to_json
  end

  def create_aws_user(user_name, role, password)
    iam_client = Aws::IAM::Client.new
    response = iam_client.create_user(user_name: user_name)
    iam_client.wait_until(:user_exists, user_name: user_name)
    iam_client.create_login_profile(
      password: password,
      password_reset_required: true,
      user_name: user_name
    )
    iam_client.add_user_to_group(
      user_name: user_name,
      group_name: role
    )
  end

  def create_github_user(team_name, user_name)
    client = Octokit::Client.new(:access_token => ENV['GITHUB_ACCESS_KEY'])
    teams = client.organization_teams(ENV['GITHUB_ORG_NAME'])
    team_id = teams.filter { |team| team[:name].downcase.eql?(team_name.downcase)  }.first[:id]
    client.add_team_membership(team_id, user_name)
  end

  def create_datadog_user(email)
    client = Dogapi::Client.new(ENV['DATADOG_API_KEY'],ENV['DATADOG_APP_KEY'])
    client.create_user({ handle: email, name: email.split('@').first })
  end

  def create_metabase_user(email, password, group_name)
    user_name = email.split('@').first
    client = Metabase::Client.new(url: ENV['METABASE_URL'], username: ENV['METABASE_USER'], password: ENV['METABASE_PASSWORD'])
    client.login
    groups = client.groups
    group_id = groups.filter { |group| group["name"].downcase.eql?(group_name.downcase) }.first["id"]
    client.create_user(first_name: user_name, last_name: 'porter', email: email, password: password, group_ids: [1, group_id])
  end

  def create_db_users_on_staging(databases, email, password)
    user_name = email.split('@').first.gsub(/[^0-9A-Za-z]/, '')
    databases.split(",").each do |dbname|
      database = DatabaseCredential.where("allowed_databases like ?", "%#{dbname}%").first
      if database
        conn = PG.connect(host: database.db_host, port: database.db_port, user: database.db_user, password: database.db_password, dbname: database.db_name)
        conn.exec( "CREATE ROLE #{user_name} LOGIN PASSWORD '#{password}'; GRANT ALL PRIVILEGES ON DATABASE \"#{dbname}\" to #{user_name};" )
        conn.close
      end
    end
  end
end


# [Pending] Jenkins - https://www.greenreedtech.com/creating-jenkins-credentials-via-the-rest-api/
# [Pending] Grafana - https://github.com/hartfordfive
# Slack - https://github.com/slack-ruby/slack-ruby-client
# ClickUp - https://clickup.com/api