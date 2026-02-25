# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_02_25_100750) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_trgm"
  enable_extension "plpgsql"

  create_table "banned_ips", force: :cascade do |t|
    t.string "ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "reason"
    t.index ["ip"], name: "index_banned_ips_on_ip"
  end

  create_table "blocked_user_data", force: :cascade do |t|
    t.string "username"
    t.string "hashed_email"
    t.string "hashed_username"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["hashed_email"], name: "index_blocked_user_data_on_hashed_email", unique: true
    t.index ["hashed_username"], name: "index_blocked_user_data_on_hashed_username", unique: true
    t.index ["username"], name: "index_blocked_user_data_on_username", unique: true
  end

  create_table "bug_reports", force: :cascade do |t|
    t.string "title"
    t.text "body"
    t.string "platform"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", default: "new"
    t.string "url"
    t.string "user_agent"
    t.string "created_from"
    t.text "steps"
    t.string "ip"
    t.string "request_method"
    t.string "media_type"
    t.string "post_parameters"
    t.index ["user_id"], name: "index_bug_reports_on_user_id"
  end

  create_table "favorite_quizzes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "quiz_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["quiz_id"], name: "index_favorite_quizzes_on_quiz_id"
    t.index ["user_id"], name: "index_favorite_quizzes_on_user_id"
  end

  create_table "languages", force: :cascade do |t|
    t.string "name"
    t.string "locale"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "quiz_reports", force: :cascade do |t|
    t.string "status", default: "open"
    t.text "description"
    t.boolean "sexual", default: false
    t.boolean "violence", default: false
    t.boolean "hate", default: false
    t.boolean "spam", default: false
    t.boolean "child_abuse", default: false
    t.boolean "mobbing", default: false
    t.bigint "quiz_id"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["quiz_id"], name: "index_quiz_reports_on_quiz_id"
    t.index ["user_id"], name: "index_quiz_reports_on_user_id"
  end

  create_table "quizzes", force: :cascade do |t|
    t.string "uuid", null: false
    t.text "description"
    t.string "visibility"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "from", null: false
    t.bigint "to", null: false
    t.string "title"
    t.integer "translations_count", default: 0
    t.index ["user_id"], name: "index_quizzes_on_user_id"
    t.index ["uuid"], name: "index_quizzes_on_uuid", unique: true
  end

  create_table "scores", force: :cascade do |t|
    t.integer "cards", default: 0
    t.integer "smart", default: 0
    t.integer "write", default: 0
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "multi", default: 0
    t.boolean "favorite", default: false, null: false
    t.bigint "translation_id"
    t.index ["translation_id"], name: "index_scores_on_translation_id"
    t.index ["user_id", "translation_id"], name: "index_scores_on_user_id_and_translation_id", unique: true
    t.index ["user_id"], name: "index_scores_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.string "session_id", null: false
    t.string "session_token_digest", null: false
    t.bigint "user_id", null: false
    t.datetime "expires", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "from", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id"
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "settings", force: :cascade do |t|
    t.boolean "dark_mode", default: true
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "locale", default: "en"
    t.integer "write_amount", default: 2
    t.integer "cards_amount", default: 2
    t.integer "multi_amount", default: 2
    t.integer "round_amount", default: 10
    t.index ["user_id"], name: "index_settings_on_user_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.float "amount"
    t.text "description"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "removed", default: false
    t.index ["user_id"], name: "index_transactions_on_user_id"
  end

  create_table "translations", force: :cascade do |t|
    t.string "word"
    t.string "translation"
    t.bigint "quiz_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["quiz_id"], name: "index_translations_on_quiz_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "username"
    t.string "role", default: "user"
    t.boolean "agb"
    t.string "unconfirmed_email"
    t.boolean "confirmed", default: false
    t.datetime "confirmed_at"
    t.integer "sign_in_count", default: 1
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "banned", default: false
    t.string "ban_reason"
    t.string "password_digest"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "bug_reports", "users"
  add_foreign_key "favorite_quizzes", "quizzes"
  add_foreign_key "favorite_quizzes", "users"
  add_foreign_key "quiz_reports", "quizzes"
  add_foreign_key "quiz_reports", "users"
  add_foreign_key "quizzes", "languages", column: "from"
  add_foreign_key "quizzes", "languages", column: "to"
  add_foreign_key "quizzes", "users"
  add_foreign_key "scores", "translations"
  add_foreign_key "scores", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "settings", "users"
  add_foreign_key "transactions", "users"
  add_foreign_key "translations", "quizzes"
end
