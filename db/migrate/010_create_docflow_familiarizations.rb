class CreateDocflowFamiliarizations < ActiveRecord::Migration
  def change
    create_table :docflow_familiarizations do |t|
      t.integer  :user_id, :null => false
      t.integer  :docflow_version_id, :null => false
      t.datetime :done_date, :null => false
    end
  end
end
