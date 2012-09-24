#  coding: utf-8
class CreateDocflowCategories < ActiveRecord::Migration
  def change
    create_table :docflow_categories do |t|
      # default deparment+user title for new document approvial fields
      t.string    :name
      t.integer   :editor_department_id, :default => 1
      t.integer   :editor_title_id, :default => 1
      t.integer   :default_approver_id

      t.integer   :parent_id
      t.integer   :lft
      t.integer   :rgt
    end

    DocflowCategory.create(:name => "Корневая категория")
  end
end