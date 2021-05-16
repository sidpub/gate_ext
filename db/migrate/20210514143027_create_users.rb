class CreateUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :users do |t|
      t.string  :email
      t.string  :github_user
      t.text    :ssh_key
      t.integer :group_id
    end
  end
end
