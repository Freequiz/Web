class User::SessionsController < ApplicationController
  before_action { setup_locale "user.sessions" }

  def new
    redirect_to user_path, notice: tp("already_logged_in") if logged_in?
    @return_path = params[:gg]
  end

  def create
    override_action "new"

    user = User.where("lower(username) = ?", params[:username].downcase)

    user = [User.find_by(email: params[:username].downcase)] unless user.first

    unless user.first && user.length == 1
      flash.now.alert = tp("wrong_username")
      return render :new, status: :unprocessable_entity
    end

    user = user.first

    if user.authenticate params[:password]
      expires = if params[:remember] == "1"
                  1.year.from_now
                else
                  1.day.from_now
                end

      SessionManager.set_login_cookies(user, expires, cookies)

      user.sign_in
      # Reset the locale in session store to allow the saved one to take over
      session[:locale] = nil
      redirect_to(params[:gg].present? ? params[:gg] : user_path, notice: tp("success").sub("%s", user.username))
    else
      flash.now.alert = tp("wrong_password")
      render :new, status: 401
    end
  end

  def destroy
    session_id = cookies.encrypted[:session_id]
    Session.find_by(session_id:)&.destroy
    cookies.delete :session_id
    cookies.delete :session_token

    # Legacy session cookie
    cookies.delete :_session_token

    session[:locale] = nil
    session[:user_id] = nil
    redirect_to user_login_path, notice: tp("success")
  end
end
