#  coding: utf-8
class CreateDocflows < ActiveRecord::Migration
  def change
    create_table :docflows do |t|
      t.string    :title
      t.integer   :responsible_id, :null => false
      t.integer   :docflow_category_id, :null => false
      t.integer   :docflow_type_id, :null => false
      t.string    :description

      t.timestamps
    end

  end
end
