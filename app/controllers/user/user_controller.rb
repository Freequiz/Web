class User::UserController < ApplicationController
  before_action { setup_locale "user.user" }
  before_action :require_login!, except: %i[new create public change_lang]

  def show
    @user_data = {
      tg("username") => @user.username,
      tg("email") => @user.email,
      tp("data.unconfirmed_email") => @user.unconfirmed_email,
      tp("data.email_verified") => @user.verified? ? tg("c_yes") : tg("c_no"),
      tg("role") => tg("roles.#{@user.role}")
    }.compact

    @login_data = {
      tp("data.total_logins") => @user.sign_in_count,
      tp("data.last_at") => @user.current_sign_in_at
    }
  end

  def public
    @target = User.find_by(username: params[:username])
    return redirect_to root_path unless @target.present?

    @quizzes = @target.quizzes.where(visibility: "public")
    results = Quiz.search_quizzes @quizzes, params
    @quizzes = results.first
    @pages = results.last
    @params = params.permit(:title, :sort, :page, :commit)
  end

  def favorites
    favorites = @user.get_favorite_quizzes
    result = Quiz.search_quizzes favorites, params
    @quizzes = result.first
    @pages = result.last
  end

  def quizzes
    result = Quiz.search_user_quizzes @user, params
    @quizzes = result.first
    @pages = result.last
    @params = user_quizzes_params
  end

  def library
    @quizzes = @user.quizzes.order(created_at: :desc).limit(10)
  end

  def new
    return redirect_to user_path, notice: tp("already_has_account") if logged_in?

    @new_user = User.new
  end

  def create
    override_action "new"

    @new_user = User.new(user_params)

    @new_user.current_sign_in_at = Time.now

    if @new_user.save
      expires_in = 14.days
      token = @new_user.signed_id(purpose: :login, expires_in:)

      cookies.encrypted[:_session_token] = {
        value: token,
        expires: Time.now + expires_in
      }

      redirect_to user_verification_pending_path, notice: tp("created").sub("%s", @new_user.username)
    else
      flash.now.alert = @new_user.get_errors
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    override_action "edit"

    email_changed, errors = @user.change(edit_params)
    if errors.length.positive?
      flash.now.alert = errors
      render :edit, status: :unprocessable_entity
    else
      messages = [tp("saved_data")]
      messages.append(tp("new_email")) if email_changed
      redirect_to user_path, notice: messages
    end
  end

  def settings; end

  def change_lang
    if logged_in?
      @user.setting.update locale: params[:locale] if Setting::LOCALES.include? params[:locale]

      session[:locale] = @user.setting.locale
    else
      cookies.permanent[:locale] = params[:locale]
      session[:locale] = params[:locale]
    end
    redirect_to params[:return_to]
  end

  def update_settings
    @user.setting.update(setting_params)

    session[:locale] = @user.setting.locale

    redirect_to user_settings_path, notice: tp("saved")
  end

  def request_destroy
    @token = @user.signed_id purpose: :destroy_user, expires_in: 1.day
  end

  def destroy
    user = User.find_signed params[:destroy_token], purpose: :destroy_user

    if user.present? && user == @user
      @user.quizzes.destroy_all if params[:destroy_quizzes] == "1"
      @user.destroy
      redirect_to root_path, notice: tp("deleted")
    else
      redirect_to user_path, alert: tp("failed")
    end
  end

  private

  def user_params
    params.require(:user).permit(
      :username,
      :email,
      :password,
      :password_confirmation,
      :agb
    )
  end

  def edit_params
    params.require(:user).permit(
      :username,
      :email,
      :password,
      :password_confirmation,
      :password_challenge
    )
  end

  def setting_params
    params.require(:setting).permit(Setting::SETTING_KEYS, :locale)
  end

  def user_quizzes_params
    params.permit(:title, :sort, :commit, :page)
  end
end
