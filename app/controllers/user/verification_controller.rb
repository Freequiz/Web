class User::VerificationController < ApplicationController
  before_action :require_login!, except: %i[verify success]

  before_action { setup_locale "user.verification" }

  def verify
    @user_target = User.find_signed params[:verification_token], purpose: :verify_email
    return redirect_to user_verification_success_path if @user_target&.verified? && @user_target.unconfirmed_email.nil?

    if @user_target.present?
      if @user_target.verified? && @user_target.unconfirmed_email.present?
        @user_target.email = @user_target.unconfirmed_email
        @user_target.unconfirmed_email = nil
      else
        @user_target.confirmed = true
      end

      @user_target.confirmed_at = Time.now
      @user_target.save

      redirect_to user_verification_success_path
    else
      redirect_to user_verification_success_path(invalid: 1)
    end
  end

  def success
    return unless (params[:expired].present? || params[:invalid].present?) && @user&.verified?

    redirect_to user_verification_success_path
  end

  def pending
    return unless @user.verified?

    redirect_to user_path, notice: tp("already_verified")
  end

  def send_email
    override_action "pending"

    redirect_to user_path, notice: @user.send_verification_email ? tp("sent") : tp("already_verified")
  end
end
