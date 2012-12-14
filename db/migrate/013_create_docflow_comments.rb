#  coding: utf-8
class CreateDocflowComments < ActiveRecord::Migration
  def change
    create_table :docflow_comments do |t|
      # t.integer   :commentable_id
      # t.string    :commentable_type
      t.references :commentable, :polymorphic => true # same as previous two
      t.integer    :user_id, :null => false
      t.text       :notes

      t.timestamps
    end

  end
end
