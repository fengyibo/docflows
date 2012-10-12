class AddDescriptionToDocflowVersions < ActiveRecord::Migration
  def change
    add_column :docflow_versions, :description, :string
    # change_table :docflow_versions do |t|
    #   t.string  :description
    # end
  end
end
