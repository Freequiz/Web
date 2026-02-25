class AddFromToSession < ActiveRecord::Migration[7.1]
  def change
    add_column :sessions, :from, :string, null: false
  end
end
