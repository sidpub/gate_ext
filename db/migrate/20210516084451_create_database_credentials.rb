class CreateDatabaseCredentials < ActiveRecord::Migration[6.1]
  def change
    create_table :database_credentials do |t|
      t.string  :db_host
      t.string  :db_port
      t.string  :db_name
      t.string  :db_user
      t.string  :db_password
      t.string  :db_env
      t.string  :allowed_databases
    end
  end
end
