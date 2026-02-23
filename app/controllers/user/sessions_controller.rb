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

        if user.first.authenticate params[:password]
            if params[:remember] == "1"
                token = user.first.signed_id(purpose: :login, expires_in: 20.years)
                cookies.encrypted.permanent[:_session_token] = token
            end

            session[:user_id] = user.first.id

            user.first.sign_in
            # Reset the locale in session store to allow the saved one to take over
            session[:locale] = nil
            redirect_to(params[:gg].present? ? params[:gg] : user_path, notice: tp("success").sub("%s", user.first.username))
        else
            flash.now.alert = tp("wrong_password")
            render :new, status: 401
        end
    end

    def destroy
        cookies.delete :_session_token
        session[:locale] = nil
        session[:user_id] = nil
        redirect_to user_login_path, notice: tp("success")
    end
end
