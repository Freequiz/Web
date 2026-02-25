class AddNullRestrictionsToSession < ActiveRecord::Migration[7.1]
  def change
    change_column_null :sessions, :session_id, false
    change_column_null :sessions, :session_token_digest, false
    change_column_null :sessions, :expires, false
  end
end
