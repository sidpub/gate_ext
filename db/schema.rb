# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_05_16_084451) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "database_credentials", force: :cascade do |t|
    t.string "db_host"
    t.string "db_port"
    t.string "db_name"
    t.string "db_user"
    t.string "db_password"
    t.string "db_env"
    t.string "allowed_databases"
  end

  create_table "groups", force: :cascade do |t|
    t.string "name"
    t.string "github_group"
    t.string "metabase_group"
    t.string "sentry_group"
    t.string "slack_channels"
    t.string "google_groups"
    t.string "aws_iam_role"
    t.string "staging_databases"
    t.string "production_databases"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "github_user"
    t.text "ssh_key"
    t.integer "group_id"
  end

end
