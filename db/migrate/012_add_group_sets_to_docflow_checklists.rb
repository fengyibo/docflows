class AddGroupSetsToDocflowChecklists < ActiveRecord::Migration
  def change
    add_column :docflow_checklists, :group_set_id, :integer
  end
end
