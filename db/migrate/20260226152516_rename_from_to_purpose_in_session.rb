class RenameFromToPurposeInSession < ActiveRecord::Migration[7.1]
  def change
    rename_column :sessions, :from, :purpose
  end
end
