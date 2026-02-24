require "test_helper"

class User::UserControllerTest < ActionDispatch::IntegrationTest
  test "can visit sign up page" do
    get user_create_path
    assert_response :success
  end

  test "can visit public page" do
    get user_public_path(:one)
    assert_response :success
  end

  test "can change language without being logged in" do
    patch change_language_path, params: { locale: :de, return_to: "/" }
    assert_redirected_to "/"
  end

  test "do not redirect language change to other domain" do
    assert_raises(ActionController::Redirecting::UnsafeRedirectError) do
      patch change_language_path, params: { locale: :de, return_to: "https://google.com" }
    end
  end

  test "can create user" do
    assert_difference "User.count", 1 do
      assert_emails 1 do
        post user_create_path, params: { user: {
          username: "Testing",
          email: "testing@freequiz.ch",
          password: "GoodPassword123",
          password_confirmation: "GoodPassword123",
          agb: true
        } }
        assert_redirected_to user_verification_pending_path
      end
    end
  end

  test "redirect from sign up page when logged in" do
    sign_in :two
    get user_create_path
    assert_redirected_to user_path
  end

  test "can get user show path" do
    sign_in :one
    get user_path
    assert_response :success
  end

  test "can view user public path" do
    get user_public_path(users(:one).username)
    assert_response :success
  end

  test "can view favorites" do
    sign_in :one
    get user_favorites_path
    assert_response :success
  end

  test "can view quizzes" do
    sign_in :one
    get user_quizzes_path
    assert_response :success
  end

  test "can view library" do
    sign_in :one
    get user_library_path
    assert_response :success
  end

  test "can view edit" do
    sign_in :one
    get user_edit_path
    assert_response :success
  end

  test "can update username" do
    sign_in :one
    id = users(:one).id
    assert_emails 0 do
      assert_changes -> { User.find(id).username } do
        patch user_edit_path, params: { user: { username: "one2" } }
        assert_redirected_to user_path
      end
    end
  end

  test "can not update username to taken one" do
    sign_in :one
    id = users(:one).id
    assert_emails 0 do
      assert_no_changes -> { User.find(id).username } do
        patch user_edit_path, params: { user: { username: "two" } }
        assert_response :unprocessable_entity
      end
    end
  end

  test "can update password" do
    sign_in :one
    id = users(:one).id
    assert_emails 0 do
      assert_changes -> { User.find(id).password_digest } do
        patch user_edit_path, params: { user: {
          password: "GoodPassword123",
          password_confirmation: "GoodPassword123",
          password_challenge: "one"
        } }
        assert_redirected_to user_path
        assert User.find(id).authenticate("GoodPassword123")
      end
    end
  end

  test "can not update password with invalid challenge" do
    sign_in :one
    id = users(:one).id
    assert_emails 0 do
      assert_no_changes -> { User.find(id).password_digest } do
        patch user_edit_path, params: { user: {
          password: "GoodPassword123",
          password_confirmation: "GoodPassword123",
          password_challenge: "wrong"
        } }
        assert_response :unprocessable_entity
        assert User.find(id).authenticate("one")
      end
    end
  end

  test "can not update password with non matching passwords" do
    sign_in :one
    id = users(:one).id
    assert_emails 0 do
      assert_no_changes -> { User.find(id).password_digest } do
        patch user_edit_path, params: { user: {
          password: "GoodPassword123",
          password_confirmation: "OtherPassword345",
          password_challenge: "one"
        } }
        assert_response :unprocessable_entity
        assert User.find(id).authenticate("one")
      end
    end
  end

  test "can not update password with password not meeting requirements" do
    sign_in :one
    id = users(:one).id
    assert_emails 0 do
      assert_no_changes -> { User.find(id).password_confirmation } do
        patch user_edit_path, params: { user: {
          password: "short",
          password_confirmation: "short",
          password_challenge: "one"
        } }
        assert_response :unprocessable_entity
        assert User.find(id).authenticate("one")
      end
    end
  end

  def update_email(id)
    assert_no_changes -> { User.find(id).email } do
      assert_changes -> { User.find(id).unconfirmed_email } do
        assert_emails 1 do
          patch user_edit_path, params: { user: {
            email: "one@freequiz.ch"
          } }
          assert_redirected_to user_path
        end
      end
    end
  end

  test "can update email" do
    sign_in :one
    update_email users(:one).id
  end

  test "can remove unconfirmed email" do
    sign_in :one
    id = users(:one).id
    update_email id
    assert_no_changes -> { User.find(id).email } do
      assert_changes -> { User.find(id).unconfirmed_email } do
        assert_emails 0 do
          patch user_edit_path, params: { user: { email: "one@one.one" } }
        end
      end
    end
  end

  test "can change unconfirmed email" do
    sign_in :one
    id = users(:one).id
    update_email id
    assert_no_changes -> { User.find(id).email } do
      assert_changes -> { User.find(id).unconfirmed_email } do
        assert_emails 1 do
          patch user_edit_path, params: { user: { email: "one2@freequiz.ch" } }
        end
        assert_redirected_to user_path
      end
    end
  end

  test "can not change email to taken one" do
    sign_in :one
    id = users(:one).id
    assert_no_changes -> { User.find(id).email } do
      assert_no_changes -> { User.find(id).unconfirmed_email } do
        patch user_edit_path, params: { user: { email: "two@two.two" } }
      end
      assert_response :unprocessable_entity
    end
  end

  test "can not change email to taken unconfirmed email" do
    sign_in :one
    update_email users(:one).id
    sign_in :two
    id = users(:two).id
    assert_no_changes -> { User.find(id).email } do
      assert_no_changes -> { User.find(id).unconfirmed_email } do
        patch user_edit_path, params: { user: { email: "one@freequiz.ch" } }
        assert_response :unprocessable_entity
      end
    end
  end

  test "can view settings" do
    sign_in :one
    get user_settings_path
    assert_response :success
  end

  test "can update settings" do
    sign_in :one
    id = users(:one).id
    assert_changes -> { User.find(id).setting.dark_mode } do
      patch user_settings_path, params: { setting: { dark_mode: 1 } }
      assert_redirected_to user_settings_path
    end
  end

  test "can request destroy token" do
    sign_in :one
    get user_delete_path
    assert_response :success
  end

  test "can delete account" do
    sign_in :one

    get user_delete_path
    assert_response :success

    assert_difference "User.count", -1 do
      delete user_delete_path(assigns(:token))
    end
  end

  test "can not destroy user when not logged in" do
    token = users(:one).signed_id expires_in: 1.day, purpose: :destroy_user
    assert_no_difference "User.count" do
      delete user_delete_path(token)
    end
  end

  test "can not destroy user with wrong token" do
    sign_in :one
    assert_no_difference "User.count" do
      delete user_delete_path("wrong token")
    end
  end
end
