#  coding: utf-8 
class CreateDocflowTypes < ActiveRecord::Migration
  def change
    create_table :docflow_types do |t|
      t.string :name
    end

    DocflowType.create(:name => "Инструкция")
    DocflowType.create(:name => "Приказ")
    DocflowType.create(:name => "Регламент")
  end
end
