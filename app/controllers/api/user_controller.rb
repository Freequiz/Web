class Api::UserController < ApplicationController
  include ApiUtils

  protect_from_forgery with: :null_session
  around_action :locale_en
  skip_before_action :setup_login
  skip_around_action :switch_locale

  before_action :api_require_valid_access_token!, except: %i[create login search public username_validator]

  def search
    query = ActiveRecord::Base.connection.quote(params[:query])
    page = params[:page] || 1
    offset = (page.to_i * 50) - 50
    @next_page = User.count > offset + 50
    @users =
      User.find_by_sql(
        "SELECT * FROM users ORDER BY SIMILARITY(username, #{query}) DESC LIMIT 50 OFFSET #{offset}"
      )
  end

  def quizzes
    page = params[:page] || 1
    offset = (page.to_i * 50) - 50
    next_page = @api_user.quizzes.count > offset + 50
    quizzes =
      @api_user.quizzes.order(created_at: :desc).limit(50).offset(offset)

    render json: { success: true, next_page:, data: quizzes.map { |q| q.data(@api_user) } }
  end

  def favorites
    page = params[:page] || 1
    offset = (page.to_i * 50) - 50
    next_page = @api_user.quizzes.count > offset + 50
    quizzes =
      @api_user.get_favorite_quizzes.limit(50).offset(offset)

    render json: { success: true, next_page:, data: quizzes.map { |q| q.data(@api_user) } }
  end

  def public
    unless (user = User.find_by(username: params[:username])).present?
      return(
          json(
            {
              success: false,
              token: "user.notfound",
              message: "User doesn't exist"
            },
            :not_found
          )
        )
    end

    page = params[:page] || 1
    offset = (page.to_i * 50) - 50
    next_page = user.quizzes.count > offset + 50
    quizzes =
      user
      .quizzes
      .where(visibility: "public")
      .order(created_at: :desc)
      .limit(50)
      .offset(offset)

    render json: { success: true, avatar_url: user.avatar_url, next_page:, data: quizzes.map { |q| q.data(@api_user) } }
  end

  def username_validator
    return json({ success: true, valid: false, token: "username.blocked" }, :not_acceptable) if BlockedUserDatum.username_blocked? params[:username]

    return json({ success: true, valid: false, token: "username.taken" }, :conflict) if User.exists? username: params[:username]

    json({ success: true, valid: true })
  end

  def create
    # json parameters like this:
    # {
    #   "user": {
    #     "username": "username",
    #     "email": "email",
    #     "password": "password",
    #     "password_confirmation": "password",
    #     "agb": true
    #   }
    # }

    unless validate_params(
      :username,
      :email,
      :password,
      :password_confirmation,
      :agb,
      hash: user_params
    )
      return(
          json(
            {
              success: false,
              token: "fields.missing",
              message:
                      "Missing username, email, password, password_confirmation or agb"
            },
            400
          )
        )
    end

    unless user_params[:password].match?(
      /^(?=.*[A-Z])(?=.*[a-z])(?=.*\d).{8,}$/
    )
      return(
          json(
            {
              success: false,
              token: "password.invalid",
              message: "Password doesn't meet requirements"
            },
            400
          )
        )
    end

    user = User.new user_params
    user.current_sign_in_at = Time.now

    if user.save
      json(
        {
          success: true,
          message: "User created",
          access_token: generate_access_token(user)
        },
        201
      )
    else
      json(
        {
          success: false,
          token: "record.invalid",
          errors: user.errors.details,
          message: "Something went wrong whilst creating the user"
        },
        400
      )
    end
  end

  def login
    unless validate_params :username, :password
      return(
          json(
            {
              success: false,
              tokne: "fields.missing",
              message: "Missing username or password"
            },
            400
          )
        )
    end

    user = User.find_by(email: params[:username].downcase)

    user = User.where("lower(username) = ?", params[:username].downcase).first unless user.present?

    unless user.present?
      return(
          json(
            {
              success: false,
              token: "user.notfound",
              message: "User doesn't exist"
            },
            :not_found
          )
        )
    end

    unless user.authenticate params[:password]
      return(
          json(
            {
              success: false,
              token: "password.invalid",
              message: "Wrong password"
            },
            401
          )
        )
    end

    user.sign_in

    return json({ success: false, token: "user.banned", reason: user.ban_reason }, :unauthorized) if user.banned

    json({ success: true, access_token: generate_access_token(user) })
  end

  def refresh_token
    json({ success: true, access_token: refresh_access_token })
  end

  def request_delete_token
    json(
      {
        success: true,
        token: @api_user.signed_id(purpose: :destroy_user, expires_in: 1.day),
        expire: 1.day.from_now.to_i
      }
    )
  end

  def destroy
    user = User.find_signed(params[:destroy_token], purpose: :destroy_user)

    if user.present? && user == @api_user
      user.quizzes.destroy_all if params[:destroy_quizzes] == "1" || params[:destroy_quizzes] == "true"
      user.destroy
      json({ success: true, message: "User deleted" })
    else
      json(
        {
          success: false,
          token: "token.invalid",
          message: "Couldn't delete user. Wrong token"
        },
        :unauthorized
      )
    end
  end

  def update
    # json parameters like this:
    # {
    #   "user": {
    #     "username": "username",
    #     "email": "email",
    #     "password": "password",
    #     "password_confirmation": "password",
    #     "old_password": "old_password"
    #   }
    # }

    if edit_params[:password].present? && !edit_params[:password].match?(
      /^(?=.*[A-Z])(?=.*[a-z])(?=.*\d).{8,}$/
    )
      return(
          json(
            {
              success: false,
              token: "password.invalid",
              message: "Password doesn't meet requirements"
            },
            400
          )
        )
    end

    email_changed, errors = @api_user.change edit_params

    if errors.length.positive?
      return(
          json(
            {
              success: false,
              token: "record.invalid",
              errors: @api_user.errors.details,
              message: "Something went wrong whilst updating the user"
            },
            :bad_request
          )
        )
    end

    json(
      { success: true, message: "User updated", email_changed: },
      :accepted
    )
  end

  def update_settings
    # json parameters like this:
    # {
    #   "setting": {
    #     "dark_mode": true,
    #     "show_email": false
    #   }
    # }

    if @api_user.setting.update(setting_params)
      render json:
          {
            success: true,
            message: "Settings updated",
            settings: @api_user.setting.as_json(except: %i[id created_at updated_at user_id])
          },
             status: :accepted

    else
      json(
        {
          success: false,
          token: "record.invalid",
          errors: @api_user.setting.errors.details,
          message: "Something went wrong whilst saving the settings"
        },
        :bad_request
      )
    end
  end

  def data
    @settings = { locale: @api_user.setting.locale }
    Setting::SETTING_KEYS.each do |key|
      @settings[key] = @api_user.setting[key]
    end
  end

  private

  def user_params
    params.require(:user).permit(
      :email,
      :username,
      :password,
      :password_confirmation,
      :agb
    )
  end

  def edit_params
    params.require(:user).permit(
      :email,
      :username,
      :password,
      :password_confirmation,
      :password_challenge
    )
  end

  def setting_params
    params.require(:setting).permit(:locale, Setting::SETTING_KEYS)
  end
end
