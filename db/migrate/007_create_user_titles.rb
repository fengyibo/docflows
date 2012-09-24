# coding: utf-8
class CreateUserTitles < ActiveRecord::Migration
  def change
    create_table :user_titles do |t|
      t.string :name
    end

  UserTitle.create(:name => "Начальник отдела")
  end
end
