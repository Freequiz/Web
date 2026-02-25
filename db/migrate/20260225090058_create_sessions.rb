class CreateSessions < ActiveRecord::Migration[7.1]
  def change
    create_table :sessions do |t|
      t.string :session_id
      t.string :session_token_digest
      t.references :user, null: false, foreign_key: true
      t.datetime :expires

      t.timestamps
    end
    add_index :sessions, :session_id
  end
end
