module ApiUtils
  def api_require_valid_access_token!
    render "api/invalid_access_token", status: :unauthorized unless valid_access_token?
    valid_access_token?
  end

  def api_ajax_require_valid_access_token!
    api_user = api_current_user("api")
    ajax_user = api_current_user("ajax")

    any_token_valid = api_user.present? || ajax_user.present?

    @api_user = api_user || ajax_user if any_token_valid

    render "api/invalid_access_token", status: :unauthorized unless any_token_valid

    any_token_valid
  end

  def find_api_user_by_token(token, purpose = "api")
    return nil if token.nil?

    session_id, session_token = token.split(":")
    Session.authenticate(session_id, session_token, purpose)
  end

  def api_current_user(purpose = "api")
    token = request.headers["Authorization"]
    user = find_api_user_by_token(token, purpose)

    @api_user = user.present? ? user : nil
  end

  def valid_access_token?
    api_current_user.present?
  end

  def generate_access_token(user, expires_in = 1.year.from_now, purpose = "api")
    Session.create_new_session(user, expires_in, purpose) => { session_id:, session_token: }
    "#{session_id}:#{session_token}"
  end

  def refresh_access_token
    token = request.headers["Authorization"]
    user = find_api_user_by_token(token)

    return nil unless user.present?

    generate_access_token user
  end

  def validate_params(*check, hash: params)
    check.each { |p| return false unless hash[p] }
    true
  end

  def json(data, code = :ok)
    render json: data, status: code
  end
end
