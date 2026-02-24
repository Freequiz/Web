Rails.application.routes.draw do
  root "home#root"
  get "terms-of-service", to: "home#terms_of_service", as: "terms_of_service"
  get "privacy-policy", to: "home#privacy_policy", as: "privacy_policy"
  get "security-policy", to: "home#security_policy", as: "security_policy"
  get "sponsors", to: "home#sponsors", as: "sponsors"

  get "search", to: "home#search", as: "search"

  # User routes
  get "user/:username", to: "user/user#public", as: "user_public"

  scope :account do
    get "/", to: "user/user#show", as: "user"
    get "edit", to: "user/user#edit", as: "user_edit"
    patch "edit", to: "user/user#update"

    get "quizzes", to: "user/user#quizzes", as: "user_quizzes"
    get "favorites", to: "user/user#favorites", as: "user_favorites"
    get "library", to: "user/user#library", as: "user_library"

    get "settings", to: "user/user#settings", as: "user_settings"
    patch "settings", to: "user/user#update_settings"

    get "delete(/:destroy_token)",
        to: "user/user#request_destroy",
        as: "user_delete"
    delete "delete/:destroy_token", to: "user/user#destroy"
  end

  scope :password do
    get "reset", to: "user/password#reset", as: "user_password_reset"
    post "reset", to: "user/password#send_email"

    get "edit/:password_reset_token",
        to: "user/password#edit",
        as: "user_password_edit"
    post "edit/:password_reset_token", to: "user/password#update"
  end

  scope :verify do
    get "/", to: "user/verification#success", as: "user_verification_success"
    get "send", to: "user/verification#send_email", as: "user_verification_send"
    get "pending",
        to: "user/verification#pending",
        as: "user_verification_pending"
    get ":verification_token", to: "user/verification#verify", as: "user_verify"
  end

  patch "language", to: "user/user#change_lang", as: "change_language"

  get "signup", to: "user/user#new", as: "user_create"
  post "signup", to: "user/user#create"

  get "login", to: "user/sessions#new", as: "user_login"
  post "login", to: "user/sessions#create"

  get "logout", to: "user/sessions#destroy", as: "user_logout"

  # Quiz routes
  namespace :quiz do
    get "create", to: "quiz#new", as: "create"
    post "create", to: "quiz#create"

    scope ":quiz_uuid" do
      get "/", to: "quiz#show", as: "show"
      get "edit", to: "quiz#edit", as: "edit"
      patch "edit", to: "quiz#update"
      get "delete", to: "quiz#request_destroy", as: "request_destroy"
      delete "delete/:destroy_token", to: "quiz#destroy", as: "delete"

      patch "favorite", to: "quiz#favorite", as: "favorite"

      get "cards", to: "quiz#cards", as: "cards"
      get "write", to: "quiz#write", as: "write"
      get "multi", to: "quiz#multi", as: "multi"
      get "smart", to: "quiz#smart", as: "smart"

      get "report", to: "quiz#new_report", as: "report"
      post "report", to: "quiz#report"
    end
  end

  # Bug report routes
  post "report", to: "admin/bug_report#create", as: "bug_report"

  # API routes
  namespace :api do
    defaults format: :json do
      scope :user do
        get "username/validate/:username", to: "user#username_validator", as: "username_validator"
        put "create", to: "user#create", as: "user_create"
        post "login", to: "user#login", as: "user_login"
        post "refresh", to: "user#refresh_token", as: "user_refresh_token"

        get "search(/:page)", to: "user#search", as: "user_search"

        get "quizzes(/:page)", to: "user#quizzes", as: "user_quizzes"
        get "favorites(/:page)", to: "user#favorites", as: "user_favorites"
        get ":username/public(/:page)", to: "user#public", as: "user_public"

        get "delete_token", to: "user#request_delete_token", as: "user_request_delete"
        delete "delete/:destroy_token", to: "user#destroy", as: "user_destroy"

        patch "update", to: "user#update", as: "user_update"
        patch "settings", to: "user#update_settings", as: "user_update_settings"

        get "data", to: "user#data", as: "user_data"
      end

      scope :quiz do
        put "create", to: "quiz#create", as: "quiz_create"

        get "search(/:page)", to: "quiz#search", as: "quiz_search"

        scope ":quiz_id" do
          get "data", to: "quiz#data", as: "quiz_data"

          post "report", to: "quiz#report", as: "quiz_report"

          patch "update", to: "quiz#update", as: "quiz_update"
          patch "favorite", to: "quiz#favorite_quiz", as: "quiz_favorite"

          scope :score do
            patch "sync", to: "quiz#sync_score", as: "quiz_sync_score"
            patch "reset/:mode", to: "quiz#reset_score", as: "quiz_reset_score"
            patch ":score_id/favorite", to: "quiz#favorite", as: "quiz_favorite_score"
            patch ":score_id/:mode", to: "quiz#score", as: "quiz_score"
          end

          get "delete_token", to: "quiz#request_destroy", as: "quiz_request_delete"
          delete "delete/:destroy_token", to: "quiz#destroy", as: "quiz_delete"
        end
      end

      get "languages", to: "api#languages"

      put "bug/create", to: "bug_report#create"
    end

    scope :docs do
      get "/", to: "docs#index", as: "docs"
      get "users", to: "docs#users", as: "docs_users"
      get "quizzes", to: "docs#quizzes", as: "docs_quizzes"
      get "authentication", to: "docs#authentication", as: "docs_authentication"
      get "errors", to: "docs#general_errors", as: "docs_general_errors"
      get "bugs", to: "docs#bugs", as: "docs_bugs"
      get "languages", to: "docs#languages", as: "docs_languages"
    end
  end

  # Admin routes
  namespace :admin do
    get "users", to: "users#index", as: "users"

    get "ban_ip", to: "users#ban_ip_form", as: "ban_ip"
    put "ban_ip", to: "users#ban_ip"
    delete "ban_ip", to: "users#unban_ip"

    scope :bugs do
      scope :triage do
        get "/", to: "bug_report#triage", as: "bug_triage"
        get ":bug_report_id", to: "bug_report#triage_show", as: "bug_triage_show"
        patch ":bug_report_id", to: "bug_report#triage_verdict"
      end

      get "list", to: "bug_report#list", as: "bugs"

      scope ":bug_id" do
        get "/", to: "bug_report#show", as: "bug"
        patch "status", to: "bug_report#status", as: "bug_status"
      end
    end

    scope :transactions do
      get "/", to: "transaction#list", as: "transactions"
      get "removed", to: "transaction#removed", as: "removed_transactions"

      get "create", to: "transaction#new", as: "new_transaction"
      post "create", to: "transaction#create"

      scope ":transaction_id" do
        get "/", to: "transaction#show", as: "show_transaction"

        delete "delete", to: "transaction#delete", as: "delete_transaction"
        patch "restore", to: "transaction#restore", as: "restore_transaction"
      end
    end

    scope :user do
      scope ":username" do
        get "delete(/:destroy_token)",
            to: "users#destroy_token",
            as: "user_delete"
        delete "delete/:destroy_token", to: "users#destroy"

        get "ban", to: "users#ban_form", as: "user_ban"
        patch "ban", to: "users#ban"
        patch "unban", to: "users#unban", as: "user_unban"
      end

      scope "edit/:username" do
        get "/", to: "users#edit", as: "user_edit"
        patch "/", to: "users#update"
      end

      scope ":username/send" do
        get "verification",
            to: "users#send_verification",
            as: "user_send_verification"
        get "reset",
            to: "users#send_password_reset",
            as: "user_send_password_reset"
        get "email", to: "users#prepare_email", as: "user_send_email"
        post "email", to: "users#send_email"
      end
    end

    get "quiz/report/:quiz_report_id", to: "quiz#show_report", as: "quiz_report"
    get "quiz/triage", to: "quiz#triage", as: "quiz_report_triage"
    post "quiz/triage/:triage_id/ignore", to: "quiz#ignore_triage", as: "quiz_report_ignore_triage"
    scope "quiz/:quiz_id" do
      get "edit", to: "quiz#edit", as: "quiz_edit"
      post "edit", to: "quiz#update", as: "quiz_update"
      get "delete", to: "quiz#request_destroy", as: "quiz_request_delete"
      delete "delete/:delete_token", to: "quiz#destroy", as: "quiz_delete"
    end
  end
end
