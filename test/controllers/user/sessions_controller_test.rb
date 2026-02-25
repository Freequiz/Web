require "test_helper"

class User::SessionsControllerTest < ActionDispatch::IntegrationTest
  test "redirect from login page when logged in" do
    sign_in :one
    get user_login_path
    assert_redirected_to user_path
  end

  test "login without remember cookie" do
    post user_login_path, params: { username: :one, password: :one }
    assert_redirected_to user_path
    assert_equal Session.authenticate(cookie_jar.encrypted[:session_id], cookie_jar.encrypted[:session_token]), users(:one)
    assert_in_delta Session.last.expires, 1.day.from_now, 10.seconds
  end

  test "login with remember cookie" do
    post user_login_path, params: { username: :one, password: :one, remember: "1" }
    assert_redirected_to user_path
    assert_equal Session.authenticate(cookie_jar.encrypted[:session_id], cookie_jar.encrypted[:session_token]), users(:one)
    assert_in_delta Session.last.expires, 1.year.from_now, 10.seconds
  end

  test "logout" do
    sign_in :one
    get user_logout_path
    assert_redirected_to user_login_path
    assert_not cookies[:session_id].present?
    assert_not cookies[:session_token].present?
  end

  test "login with redirect" do
    post user_login_path, params: { username: :one, password: :one, gg: root_path }
    assert_redirected_to root_path
  end

  test "login with unsafe redirect" do
    assert_raises(ActionController::Redirecting::UnsafeRedirectError) do
      post user_login_path, params: { username: :one, password: :one, gg: "https://google.com" }
    end
  end

  test "login with wrong credentials" do
    post user_login_path, params: { username: :one, password: :wrong }
    assert_response :unauthorized
  end

  test "no redirect on login with wrong credentials" do
    post user_login_path, params: { username: :one, password: :wrong, gg: root_path }
    assert_response :unauthorized
  end

  test "login with wrong username" do
    post user_login_path, params: { username: :wrong, password: :one }
    assert_response :unprocessable_entity
  end
end
