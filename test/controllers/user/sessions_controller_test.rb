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
    assert_equal Session.authenticate(cookie_jar.encrypted[:session_id], cookie_jar.encrypted[:session_token], "web"), users(:one)
    assert_in_delta Session.last.expires, 1.day.from_now, 10.seconds
  end

  test "login with remember cookie" do
    post user_login_path, params: { username: :one, password: :one, remember: "1" }
    assert_redirected_to user_path
    assert_equal Session.authenticate(cookie_jar.encrypted[:session_id], cookie_jar.encrypted[:session_token], "web"), users(:one)
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

  test "cannot use legacy session[:user_id] to log in" do
    get root_path
    session[:user_id] = users(:one).id
    get user_path
    assert_response :redirect
  end

  test "cannot use legacy signed id to log in" do
    signed_id = users(:one).signed_id purpose: :login, expires_at: 1.day.from_now
    get root_path
    cookie_jar.encrypted[:_session_token] = { value: signed_id, expires_in: 1.day.from_now }
    get user_path
    assert_response :redirect
  end

  test "session expiry after 1 day" do
    sign_in :one, remember: false
    get user_path
    assert_response :success
    assert_not Session.last.expired?
    travel 1.day - 10.seconds do
      get user_path
      assert_response :success
      assert_not Session.last.expired?
    end
    travel 1.day + 10.seconds do
      get user_path
      assert_response :redirect
      assert Session.last.expired?
    end
  end

  test "session expiry after 1 year" do
    sign_in :one, remember: true
    get user_path
    assert_response :success
    assert_not Session.last.expired?
    travel 1.year - 10.seconds do
      get user_path
      assert_response :success
      assert_not Session.last.expired?
    end
    travel 1.year + 10.seconds do
      get user_path
      assert_response :redirect
      assert Session.last.expired?
    end
  end
end
