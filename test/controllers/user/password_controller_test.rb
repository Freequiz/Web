require "test_helper"

class User::PasswordControllerTest < ActionDispatch::IntegrationTest
  test "can visit password reset path" do
    get user_password_reset_path
    assert_response :success
  end

  test "can not visit password reset path when logged in" do
    sign_in :one
    get user_password_reset_path
    assert_redirected_to user_path
    assert_equal flash.notice, I18n.t("user.sessions.new.already_logged_in")
  end

  test "password reset email is sent" do
    assert_emails 1 do
      post user_password_reset_path, params: { username: :one }
    end
  end

  test "can not get password edit with invalid token" do
    get user_password_edit_path("wrong token")
    assert_redirected_to root_path
  end

  test "can not get password edit with token with wrong purpose" do
    token = users(:one).signed_id expires_in: 1.day, purpose: :wrong
    get user_password_edit_path(token)
    assert_redirected_to root_path
  end

  test "can not get password edit with expired token" do
    token = users(:one).signed_id expires_in: 0, purpose: :reset_password
    get user_password_edit_path(token)
    assert_redirected_to root_path
  end

  test "can get password edit with valid token" do
    token = users(:one).signed_id expires_in: 1.day, purpose: :reset_password
    get user_password_edit_path(token)
    assert_response :success
  end

  test "can update password" do
    token = users(:one).signed_id expires_in: 1.day, purpose: :reset_password
    post user_password_edit_path(token), params: { password: "GoodPassword123", password_confirmation: "GoodPassword123" }
    assert_redirected_to user_path
    assert users(:one).reload.authenticate("GoodPassword123").present?
    assert_equal users(:one), Session.authenticate(cookie_jar.encrypted[:session_id], cookie_jar.encrypted[:session_token], "web")
  end

  test "can not update password with invalid token" do
    post user_password_edit_path("wrong token"), params: { password: "GoodPassword123", password_confirmation: "GoodPassword123" }
    assert_redirected_to root_path
    assert_equal I18n.t("user.password.edit.invalid_link"), flash.alert
  end

  test "can not update password with expired token" do
    token = users(:one).signed_id expires_in: 0, purpose: :reset_password
    post user_password_edit_path(token), params: { password: "GoodPassword123", password_confirmation: "GoodPassword123" }
    assert_redirected_to root_path
    assert_equal I18n.t("user.password.edit.invalid_link"), flash.alert
  end

  test "can not update password with wrong token purpose" do
    token = users(:one).signed_id expires_in: 1.day, purpose: :wrong_purpose
    post user_password_edit_path(token), params: { password: "GoodPassword123", password_confirmation: "GoodPassword123" }
    assert_redirected_to root_path
    assert_equal I18n.t("user.password.edit.invalid_link"), flash.alert
  end

  test "can not update password with non matching passwords" do
    token = users(:one).signed_id expires_in: 1.day, purpose: :reset_password
    post user_password_edit_path(token), params: { password: "GoodPassword123", password_confirmation: "OtherPassword456" }
    assert_response :unprocessable_entity
    assert users(:one).authenticate("one").present?
  end

  test "can not update password with non matching password requirements" do
    token = users(:one).signed_id expires_in: 1.day, purpose: :reset_password
    post user_password_edit_path(token), params: { password: "1", password_confirmation: "1" }
    assert_response :unprocessable_entity
    assert users(:one).authenticate("one").present?
  end
end
