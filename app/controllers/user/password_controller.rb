class User::PasswordController < ApplicationController
  before_action { setup_locale "user.password" }

  def reset
    redirect_to user_path, notice: t("user.sessions.new.already_logged_in") if logged_in?
  end

  def send_email
    override_action "reset"

    user = User.find_by_username_or_email(params[:username])

    unless user.present?
      flash.now.alert = tp("wrong_username")
      return render :reset, status: 401
    end

    user.send_reset_password_email
    redirect_to root_path, notice: tp("sent_email")
  end

  def edit
    user =
      User.find_signed params[:password_reset_token], purpose: :reset_password
    return if user.present?

    redirect_to root_path, alert: tp("invalid_link")
  end

  def update
    override_action "edit"

    user = User.find_signed params[:password_reset_token], purpose: :reset_password
    return redirect_to root_path, alert: tp("invalid_link") unless user.present?

    if user.update(
      password: params[:password],
      password_confirmation: params[:password_confirmation]
    )
      session[:user_id] = user.id

      user.sign_in

      redirect_to user_path, notice: tp("changed_password")
    else
      flash.now.alert = user.get_errors
      render :edit, status: :unprocessable_entity
    end
  end
end
