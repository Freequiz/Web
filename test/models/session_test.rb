require "test_helper"

class SessionTest < ActiveSupport::TestCase
  test "can create session" do
    session_data = Session.create_new_session(users(:one), 1.hour.from_now, "test")
    session_data => { session:, session_id:, session_token: }
    assert session.present?
    assert_equal Session::SESSION_ID_LENGTH, session_id.length
    assert_equal Session::SESSION_TOKEN_LENGTH, session_token.length
    assert_not_equal session.session_token_digest, session_token
    assert session.authenticate_session_token(session_token).present?
    assert_not session.authenticate_session_token("wrongtoken").present?
    assert_not session.authenticate_session_token("#{session_token}a")
    assert_not session.authenticate_session_token("a#{session_token}")
    assert Session.find_by(session_id: session_id).authenticate_session_token(session_token).present?
    assert session.expires < 61.minutes.from_now
  end

  test "can authenticate with session" do
    Session.create_new_session(users(:one), 1.hour.from_now, "test") => { session_id:, session_token: }
    assert_equal users(:one), Session.authenticate(session_id, session_token, "test")
  end

  test "cannot authenticate with expired session" do
    Session.create_new_session(users(:one), Time.now - 1.second, "test") => { session_id:, session_token: }
    assert_not Session.authenticate(session_id, session_token, "test")
  end

  test "cannot authenticate with wrong session id" do
    Session.create_new_session(users(:one), 1.hour.from_now, "test") => { session_id:, session_token: }
    assert_not Session.authenticate("#{session_id}a", session_token, "test")
    assert_not Session.authenticate("a#{session_id}", session_token, "test")
  end

  test "cannot authenticate with wrong session token" do
    Session.create_new_session(users(:one), 1.hour.from_now, "test") => { session_id:, session_token: }
    assert_not Session.authenticate(session_id, "#{session_token}a", "test")
    assert_not Session.authenticate(session_id, "a#{session_token}", "test")
  end

  test "cannot authenticate with wrong session from" do
    Session.create_new_session(users(:one), 1.hour.from_now, "test") => { session_id:, session_token: }
    assert_not Session.authenticate(session_id, session_token, "web")
  end
end
