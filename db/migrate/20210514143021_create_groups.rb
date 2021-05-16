class CreateGroups < ActiveRecord::Migration[6.1]
  def change
    create_table :groups do |t|
      t.string :name
      t.string :github_group
      t.string :metabase_group
      t.string :sentry_group
      t.string :slack_channels
      t.string :google_groups
      t.string :aws_iam_role
      t.string :staging_databases
      t.string :production_databases
    end
  end
end
