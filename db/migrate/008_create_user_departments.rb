# coding: utf-8
class CreateUserDepartments < ActiveRecord::Migration
  def change
    create_table :user_departments do |t|
      t.string :name
    end

    UserDepartment.create(:name => "Дирекция")
  end
end
