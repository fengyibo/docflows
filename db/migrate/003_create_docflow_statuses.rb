#  coding: utf-8
class CreateDocflowStatuses < ActiveRecord::Migration
  def change
    create_table :docflow_statuses do |t|
      t.string :name
    end

    DocflowStatus.create(:name => "Новый")
    DocflowStatus.create(:name => "На утверждении")
    DocflowStatus.create(:name => "Утвержден")
    DocflowStatus.create(:name => "Отменен")
  end
end
