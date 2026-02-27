require "test_helper"

class Api::UserControllerTest < ActionDispatch::IntegrationTest
  include ApiUtils

  test "blocked username validation" do
    get api_username_validator_path("Freequiz")

    json = @response.parsed_body

    assert json["success"]
    assert_not json["valid"]
    assert_equal "username.blocked", json["token"]
  end

  test "taken username validation" do
    get api_username_validator_path("one")

    json = @response.parsed_body

    assert json["success"]
    assert_not json["valid"]
    assert_equal "username.taken", json["token"]
  end

  test "valid username validation" do
    get api_username_validator_path("test")

    json = @response.parsed_body

    assert json["success"]
    assert json["valid"]
  end

  test "user creation" do
    assert_difference("User.count", 1) do
      assert_emails 1 do
        put api_user_create_path, params: { user: { username: "test", password: "Password123", password_confirmation: "Password123", email: "test@freequiz.ch", agb: true } }
      end
    end

    json = @response.parsed_body

    assert json["success"]
    assert_equal User.find_by(username: "test").id, find_api_user_by_token(json["access_token"]).id
  end

  test "user creation with missing data" do
    assert_no_difference("User.count") do
      put api_user_create_path, params: { user: {} }
    end

    assert_not @response.parsed_body["success"]
  end

  test "user creation with one missing field" do
    user_params = {
      username: "test",
      password: "Password123",
      password_confirmation: "Password123",
      email: "test@freequiz.ch",
      agb: true
    }

    user_params.each_key do |key|
      assert_no_difference("User.count") do
        put api_user_create_path, params: { user: user_params.except(key) }
      end

      assert_not @response.parsed_body["success"]
    end
  end

  test "user creation with invalid password" do
    passwords = %w[
      password
      password123
      Password
      abc
      AB123c
    ]

    passwords.each do |password|
      assert_no_difference("User.count") do
        put api_user_create_path, params: { user: {
          username: "test",
          password: password,
          password_confirmation: password,
          email: "test@freequiz.ch",
          agb: true
        } }

        assert_not @response.parsed_body["success"]
      end
    end
  end

  test "user creation with non-matching passwords" do
    assert_no_difference("User.count") do
      put api_user_create_path, params: { user: {
        username: "test",
        password: "Password123",
        password_confirmation: "Password1234",
        email: "test@freequiz.ch",
        agb: true
      } }

      assert_not @response.parsed_body["success"]
    end
  end

  test "user creation with invalid email" do
    emails = %w[
      test
      test@freequiz.
      abc@abc_.
    ]

    emails.each do |email|
      assert_no_difference("User.count") do
        put api_user_create_path, params: { user: {
          username: "test",
          password: "Password123",
          password_confirmation: "Password123",
          email: email,
          agb: true
        } }

        assert_not @response.parsed_body["success"]
      end
    end
  end

  test "user creation without accepting AGB" do
    assert_no_difference("User.count") do
      put api_user_create_path, params: { user: {
        username: "test",
        password: "Password123",
        password_confirmation: "Password123",
        email: "test@freequiz.ch"
      } }
    end
  end

  test "user creation with blocked username" do
    assert_no_difference("User.count") do
      put api_user_create_path, params: { user: {
        username: "Freequiz",
        password: "Password123",
        password_confirmation: "Password123",
        email: "test@freequiz.ch",
        agb: true
      } }

      assert_not @response.parsed_body["success"]
    end
  end

  test "user creation with taken username" do
    assert_no_difference("User.count") do
      put api_user_create_path, params: { user: {
        username: "one",
        password: "Password123",
        password_confirmation: "Password123",
        email: "test@freequiz.ch",
        agb: true
      } }

      assert_not @response.parsed_body["success"]
    end
  end

  test "user login" do
    assert_difference -> { users(:one).reload.sign_in_count }, 1 do
      post api_user_login_path, params: { username: "one", password: "one" }
    end
    assert_response :success
    assert_equal users(:one), find_api_user_by_token(@response.parsed_body["access_token"])
  end

  test "user login with invalid credentials" do
    post api_user_login_path, params: { username: "one", password: "two" }
    assert_response :unauthorized
  end

  test "user login with missing credentials" do
    post api_user_login_path
    assert_response :bad_request
  end

  test "user login with email" do
    assert_difference -> { users(:one).reload.sign_in_count }, 1 do
      post api_user_login_path, params: { username: "one@one.one", password: "one" }
    end
    assert_response :success
    assert_equal users(:one), find_api_user_by_token(@response.parsed_body["access_token"])
  end

  test "user login with username case difference" do
    assert_difference -> { users(:one).reload.sign_in_count }, 1 do
      post api_user_login_path, params: { username: "One", password: "one" }
    end
    assert_response :success
    assert_equal users(:one), find_api_user_by_token(@response.parsed_body["access_token"])
  end

  test "user login with email case difference" do
    assert_difference -> { users(:one).reload.sign_in_count }, 1 do
      post api_user_login_path, params: { username: "one@OnE.one", password: "one" }
    end
    assert_response :success
    assert_equal users(:one), find_api_user_by_token(@response.parsed_body["access_token"])
  end

  test "login when user is banned" do
    post api_user_login_path, params: { username: "banned", password: "banned" }
    assert_response :unauthorized
  end

  test "refresh access token" do
    post api_user_login_path, params: { username: "one", password: "one" }
    assert_response :success

    token = @response.parsed_body["access_token"]
    assert_equal users(:one), find_api_user_by_token(token)

    post api_user_refresh_token_path, headers: { "Authorization" => token }
    assert_response :success

    new_token = @response.parsed_body["access_token"]

    assert_not_equal token, new_token
    assert_equal users(:one), find_api_user_by_token(new_token)
  end

  test "refresh access token with invalid token" do
    post api_user_refresh_token_path, headers: { "Authorization" => "invalid" }
    assert_response :unauthorized
  end

  test "refresh access token with missing token" do
    post api_user_refresh_token_path
    assert_response :unauthorized
  end

  test "refresh access token with exired token" do
    token = users(:one).signed_id expires_in: 0, purpose: :api_token
    post api_user_refresh_token_path, headers: { "Authorization" => token }
    assert_response :unauthorized
  end

  test "search users" do
    get api_user_search_path, params: { page: 1, query: "on" }
    assert_response :success

    assert_equal "one", @response.parsed_body["data"].first["username"]
    assert_equal users(:one).quizzes.where(visibility: "public").count, @response.parsed_body["data"].first["quizzes"]
  end

  test "user quizzes" do
    get api_user_quizzes_path, headers: api_sign_in(:one)
    assert_response :success

    assert_equal users(:one).quizzes.count, @response.parsed_body["data"].count
  end

  test "cannot get user quizzes without token" do
    get api_user_quizzes_path
    assert_response :unauthorized
  end

  test "can get user quizzes with api token" do
    Session.create_new_session(users(:one), 1.hour.from_now, "api") => { session_id:, session_token: }
    headers = { "Authorization" => "#{session_id}:#{session_token}" }
    get(api_user_quizzes_path, headers:)
    assert_response :success
  end

  test "cannot get user quizzes with web token" do
    Session.create_new_session(users(:one), 1.hour.from_now, "web") => { session_id:, session_token: }
    headers = { "Authorization" => "#{session_id}:#{session_token}" }
    get(api_user_quizzes_path, headers:)
    assert_response :unauthorized
  end

  test "cannot get user quizzes with ajax token" do
    Session.create_new_session(users(:one), 1.hour.from_now, "ajax") => { session_id:, session_token: }
    headers = { "Authorization" => "#{session_id}:#{session_token}" }
    get(api_user_quizzes_path, headers:)
    assert_response :unauthorized
  end

  test "user favorites" do
    get api_user_favorites_path, headers: api_sign_in(:one)
    assert_response :success

    assert_equal users(:one).favorite_quizzes.count, @response.parsed_body["data"].count
  end

  test "cannot get user favorites without token" do
    get api_user_favorites_path
    assert_response :unauthorized
  end

  test "public user data" do
    get api_user_public_path("one")
    assert_response :success

    assert_equal users(:one).quizzes.where(visibility: "public").count, @response.parsed_body["data"].count
  end

  test "can request delete token" do
    get api_user_request_delete_path, headers: api_sign_in(:one)
    assert_response :success

    assert_not_nil @response.parsed_body["token"]
    assert_equal users(:one), User.find_signed(@response.parsed_body["token"], purpose: :destroy_user)
  end

  test "cannot request delete token without being logged in" do
    get api_user_request_delete_path
    assert_response :unauthorized
  end

  test "destroy user" do
    get api_user_request_delete_path, headers: api_sign_in(:one)
    assert_response :success

    token = @response.parsed_body["token"]

    assert_no_difference "Quiz.count" do
      assert_difference "User.count", -1 do
        delete api_user_destroy_path(token), headers: api_sign_in(:one)
        assert_response :success
      end
    end
  end

  test "cannot destroy user without token" do
    assert_no_difference "User.count" do
      delete api_user_destroy_path("invalid"), headers: api_sign_in(:one)
      assert_response :unauthorized
    end
  end

  test "cannot destroy user when not logged in" do
    get api_user_request_delete_path, headers: api_sign_in(:one)
    assert_response :success

    token = @response.parsed_body["token"]

    assert_no_difference "User.count" do
      delete api_user_destroy_path(token)
      assert_response :unauthorized
    end
  end

  test "can destroy all quizzes with user" do
    get api_user_request_delete_path, headers: api_sign_in(:one)
    assert_response :success

    token = @response.parsed_body["token"]

    assert_difference "Quiz.count", -users(:one).quizzes.count do
      assert_difference "User.count", -1 do
        delete api_user_destroy_path(token), params: { destroy_quizzes: "1" }, headers: api_sign_in(:one)
        assert_response :success
      end
    end
  end

  test "can update user" do
    assert_emails 1 do
      patch api_user_update_path, params: { user: { email: "otherone@one.one" } }, headers: api_sign_in(:one)
    end
    assert_response :success
    assert_equal "otherone@one.one", users(:one).reload.unconfirmed_email
  end

  test "cannot update user without being logged in" do
    assert_emails 0 do
      patch api_user_update_path, params: { user: { email: "otherone@one.one" } }
      assert_response :unauthorized
    end
  end

  test "cannot update user with invalid password" do
    patch api_user_update_path, params: { user: { password: "password", password_confirmation: "password" } }, headers: api_sign_in(:one)
    assert_response :bad_request
  end

  test "can update settings" do
    assert_changes -> { users(:one).setting.reload.locale }, from: "en", to: "de" do
      patch api_user_update_settings_path, params: { setting: { locale: "de" } }, headers: api_sign_in(:one)
      assert_response :success
    end
  end

  test "cannot update settings without being logged in" do
    patch api_user_update_settings_path, params: { setting: { locale: "de" } }
    assert_response :unauthorized
  end

  test "can get user data" do
    Session.create_new_session(users(:one), 2.hour.from_now, "api") => { session:, session_id:, session_token: }
    headers = { "Authorization" => "#{session_id}:#{session_token}" }

    # Create more session to test session data
    Session.create_new_session(users(:one), 1.hour.from_now, "web")
    Session.create_new_session(users(:one), 1.hour.from_now, "ajax")

    get(api_user_data_path, headers:)
    assert_response :success

    assert_equal users(:one).username, @response.parsed_body["data"]["username"]

    json = @response.parsed_body
    assert json.key?("success")
    assert json.key?("data")
    assert json["success"]

    data = json["data"]
    required_keys = %w[username avatar_url email unconfirmed_email role quizzes created_at updated_at settings confirmation logins]
    required_keys.each do |key|
      assert data.key?(key)
    end

    assert_equal 3, data["logins"]["sessions"].length
    data["logins"]["sessions"].each do |s|
      if s["purpose"] == "api"
        assert s["current_session"]
        assert_equal session.expires.to_i, s["expires"]
        assert_equal session.session_id, s["session_id"]
      else
        assert_not s["current_session"]
      end
    end
  end

  test "cannot get user data without being logged in" do
    get api_user_data_path
    assert_response :unauthorized
  end

  test "cannot get user data without web token" do
    Session.create_new_session(users(:one), 1.hour.from_now, "web") => { session_id:, session_token: }
    headers = { "Authorization" => "#{session_id}:#{session_token}" }
    get(api_user_data_path, headers:)
    assert_response :unauthorized
  end

  test "cannot get user data without ajax token" do
    Session.create_new_session(users(:one), 1.hour.from_now, "ajax") => { session_id:, session_token: }
    headers = { "Authorization" => "#{session_id}:#{session_token}" }
    get(api_user_data_path, headers:)
    assert_response :unauthorized
  end

  test "can logout" do
    headers = nil

    assert_changes "Session.count", 1 do
      headers = api_sign_in(:one)
      get(api_user_data_path, headers:)
      assert_response :success
    end

    assert_changes "Session.count", -1 do
      delete(api_user_logout_path, headers:)
      assert_response :success
    end

    get(api_user_data_path, headers:)
    assert_response :unauthorized
  end

  test "cannot logout when not logged in" do
    assert_no_changes "Session.count" do
      delete api_user_logout_path
      assert_response :unauthorized
    end
  end

  test "can destroy current session" do
    headers = api_sign_in(:one)
    session_id = headers["Authorization"].split(":").first

    get(api_user_data_path, headers:)
    assert_response :success

    assert_changes "Session.count", -1 do
      delete(api_user_destroy_session_path(session_id), headers:)
      assert_response :success
    end

    get(api_user_data_path, headers:)
    assert_response :unauthorized
  end

  test "can destroy session" do
    headers = api_sign_in(:one)
    Session.create_new_session(users(:one), 1.hour.from_now, "api") => { session_id:, session_token: }
    to_be_destroyed_header = { "Authorization" => "#{session_id}:#{session_token}" }

    get(api_user_data_path, headers: to_be_destroyed_header)
    assert_response :success

    assert_changes "Session.count", -1 do
      delete(api_user_destroy_session_path(session_id), headers:)
      assert_response :success
    end

    get(api_user_data_path, headers: to_be_destroyed_header)
    assert_response :unauthorized

    get(api_user_data_path, headers:)
    assert_response :success
  end

  test "cannot destroy session when not logged in" do
    Session.create_new_session(users(:one), 1.hours.from_now, "api") => { session_id:, session_token: }
    not_to_be_destroyed = { "Authorization" => "#{session_id}:#{session_token}" }

    get(api_user_data_path, headers: not_to_be_destroyed)
    assert_response :success

    assert_no_changes "Session.count" do
      delete(api_user_destroy_session_path(session_id))
      assert_response :unauthorized
    end

    get(api_user_data_path, headers: not_to_be_destroyed)
    assert_response :success
  end

  test "cannot destroy other users session" do
    headers = api_sign_in(:one)
    Session.create_new_session(users(:two), 1.hour.from_now, "api") => { session_id:, session_token: }
    not_to_be_destroyed = { "Authorization" => "#{session_id}:#{session_token}" }

    get(api_user_data_path, headers:)
    assert_response :success

    get(api_user_data_path, headers: not_to_be_destroyed)
    assert_response :success

    assert_no_changes "Session.count" do
      delete(api_user_destroy_session_path(session_id), headers:)
      assert_response :unauthorized
    end

    get(api_user_data_path, headers: not_to_be_destroyed)
    assert_response :success
  end
end
