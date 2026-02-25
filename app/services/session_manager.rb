class SessionManager
  def self.set_login_cookies(user, expires, cookies)
    # Allow cookies to be send over HTTP in non production enviorenments (test, development)
    secure = Rails.env.production?

    Session.create_new_session(user, expires, "web") => { session_id:, session_token: }
    cookies.encrypted[:session_id] = {
      value: session_id,
      expires:,
      secure:,
      httponly: true,
      same_site: :strict
    }
    cookies.encrypted[:session_token] = {
      value: session_token,
      expires:,
      secure:,
      httponly: true,
      same_site: :strict
    }
  end
end
