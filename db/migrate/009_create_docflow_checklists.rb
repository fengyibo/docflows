class CreateDocflowChecklists < ActiveRecord::Migration
  def change
    create_table :docflow_checklists do |t|
      t.integer :docflow_version_id
      t.integer :user_id
      t.integer :user_title_id
      t.integer :user_department_id
      t.string  :all_users

      t.timestamps
    end
  end
end
