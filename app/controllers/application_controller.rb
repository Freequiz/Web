class ApplicationController < ActionController::Base
  include ApiUtils

  before_action :setup_login
  around_action :switch_locale

  # Put after around_action :switch_locale for the users preferend language to be used
  # switch_locale required setup_login to have been called
  before_action :check_ban!

  def locale_en(&)
    I18n.with_locale(:en, &)
  end

  def switch_locale(&)
    if (locale = session[:locale]).present?
      I18n.with_locale(locale, &)
    else
      locale = logged_in? ? @user.setting.locale.to_sym : cookies[:locale]
      locale ||= I18n.default_locale
      I18n.with_locale(locale, &)
      session[:locale] = locale
    end
  end

  def check_ban!
    return if logged_in? && @user.admin?

    user = @user || api_current_user

    return unless user&.banned? || BannedIp.ip_banned?(request.remote_ip)

    @ban_reason = user&.get_ban_reason || BannedIp.get_reason(request.remote_ip)

    api_call = self.class.ancestors.first.name.split("::").first == "Api"
    render "errors/banned", status: :unauthorized, layout: false unless api_call
    render json: { success: false, token: "user.banned", reason: @ban_reason }, status: :unauthorized if api_call
  end

  def tp(attribute, **args)
    return unless @locale.present?

    t(
      "#{@locale[:path]}#{@locale[:action_override] ? "" : ".#{action_name}"}.#{attribute}",
      **args
    )
  end
  alias tl tp
  helper_method :tp, :tl

  def tg(attribute, pre = "", **args)
    t("general.#{pre}#{pre.present? ? "." : ""}#{attribute}", **args)
  end
  helper_method :tg

  def setup_locale(base_path)
    @locale = { path: "#{base_path}.", action_override: false }
  end

  def override_action(action)
    @locale[:path] += action.to_s
    @locale[:action_override] = true
  end

  def setup_login
    login
  end

  def logged_in?
    @user.present?
  end
  helper_method :logged_in?

  def require_login!
    unless logged_in?
      redirect_to user_login_path(gg: request.path), alert: tg("login_required")
      return false
    end
    true
  end

  def require_admin!
    raise ActionController::RoutingError, "Not Found" unless logged_in? && @user.admin?
  end

  def user_admin?
    logged_in? && @user.admin?
  end
  helper_method :user_admin?

  def current_user
    @user
  end
  helper_method :current_user

  def test_id(id)
    "data-test-id=\"#{id}\"".html_safe unless Rails.env.production?
  end
  helper_method :test_id

  private

  def login
    @user = if User.exists?(id: session[:user_id])
              User.find(session[:user_id])
            else
              User.find_signed cookies.encrypted[:_session_token], purpose: :login
            end
    @user.present?
  end
end
