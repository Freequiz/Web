class Admin::UsersController < ApplicationController
  before_action :require_admin!

  def index
    @sort_criteria = [
      ["Date created", "created_at"],
      ["Date updated", "updated_at"],
      ["Date confirmed", "confirmed_at"],
      ["Last login", "last_sign_in_at"]
    ]
    @order_criteria = [
      %w[Descending DESC],
      %w[Ascending ASC]
    ]
    @property_criteria = [
      %w[Username username],
      ["E-mail Address", "email"]
    ]

    return(@users = User.order(created_at: :desc)) unless params.key? :commit

    if params[:type].present? && params[:type] == "query"
      property = params[:property] == "username" ? "username" : "email"
      safe_query = ActiveRecord::Base.connection.quote_string(params[:query])

      valid_sort = %w[created_at updated_at confirmed_at last_sign_in_at]
      valid_direction = %w[ASC DESC]

      sort = valid_sort.include?(params[:sort]) ? params[:sort] : "created_at"
      direction =
        valid_direction.include?(params[:order]) ? params[:order] : "ASC"

      query_order = Arel.sql("#{property} ILIKE '%#{safe_query}%' DESC")
      date_order = Arel.sql("#{sort} #{direction}")

      @users = User.order(query_order, date_order)
    else
      @users = User.order("#{params[:sort]} #{params[:order]}")
    end
  end

  def edit
    @user_target = User.find_by(username: params[:username])
    @current_sign_in_location = nil
    @last_sign_in_location = nil
  end

  def update
    @user_target = User.find_by(username: params[:username])

    was_verified = @user_target.verified?
    email_before = @user_target.email

    unless @user_target.update(edit_params)
      flash.now.alert = ["Failed to save user for the following reasons"].concat(
        @user_target.get_errors
      )
      return render :edit, status: :unprocessable_entity
    end

    @user_target.update(confirmed_at: Time.now) if edit_params[:confirmed] && !was_verified

    if edit_params[:email] != email_before || (!@user_target.verified? && was_verified)
      @user_target.update(confirmed: false, confirmed_at: nil)
      @user_target.send_verification_email
      flash.notice = "Saved user and verification E-mail was sent"
    else
      flash.notice = "Saved user"
    end
    redirect_to admin_user_edit_path(@user_target.username)
  end

  def ban_form
    @user_target = User.find_by(username: params[:username])
  end

  def ban
    User.find_by(username: params[:username]).update ban_params
    flash.notice = "User banned"
    redirect_to admin_user_edit_path
  end

  def unban
    User.find_by(username: params[:username]).update banned: false
    flash.notice = "User unbanned"
    redirect_to admin_user_edit_path
  end

  def ban_ip
    return redirect_to params[:return], notice: "IP is already banned" if BannedIp.find_by(ip: ban_ip_params[:ip]).present?

    BannedIp.create ban_ip_params
    redirect_to params[:return], notice: "IP #{ban_ip_params[:ip]} was banned"
  end

  def unban_ip
    return redirect_to params[:return], notice: "IP was not banned" unless BannedIp.find_by(ip: params[:ip]).present?

    BannedIp.find_by(ip: params[:ip]).destroy
    redirect_to params[:return], notice: "IP #{params[:ip]} was unbanned"
  end

  def destroy_token
    @user_target = User.find_by(username: params[:username])
    @token = @user_target.signed_id purpose: :destroy_user, expires_in: 1.day
  end

  def destroy
    user = User.find_signed params[:destroy_token], purpose: :destroy_user

    if user.present?
      user.destroy
      flash.notice = "User deleted"
    else
      flash.alert = "Could not delete user. Retry again later"
    end
    redirect_to admin_users_path
  end

  def send_verification
    user = User.find_by(username: params[:username])
    sent = user.send_verification_email
    notice = sent ? "Verification E-mail sent to user (#{user.email})" : "Verification E-mail wasn't sent because either the user is already verified or something went wrong"
    redirect_to admin_user_edit_path(user.username), notice:
  end

  def send_password_reset
    user = User.find_by(username: params[:username])
    user.send_reset_password_email
    redirect_to admin_user_edit_path(user.username), notice: "Password reset E-mail sent to user (#{user.email})"
  end

  def prepare_email
    @user_target = User.find_by(username: params[:username])
  end

  def send_email
    user = User.find_by(username: params[:username])
    UserMailer
      .with(email: user.email, subject: params[:subject], body: params[:body])
      .email_to_user
      .deliver_later
    redirect_to admin_user_edit_path(user.username), notice: "E-mail sent to user (#{user.email})"
  end

  private

  def edit_params
    params.require(:user).permit(
      :username,
      :email,
      :unconfirmed_email,
      :role,
      :confirmed
    )
  end

  def ban_params
    params.require(:user).permit(:banned, :ban_reason)
  end

  def ban_ip_params
    params.require(:banned_ip).permit(:ip, :reason)
  end
end
