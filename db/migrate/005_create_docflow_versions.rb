class CreateDocflowVersions < ActiveRecord::Migration
  def change
    create_table :docflow_versions do |t|
      t.integer   :docflow_id, :null => false
      t.integer   :version, :null => false, :default => 1
      t.integer   :docflow_status_id, :null => false, :default => 1
      t.integer   :author_id, :null => false
      t.integer   :approver_id
      t.datetime  :approve_date
      t.datetime  :actual_date

      t.timestamps
    end
  end
end
