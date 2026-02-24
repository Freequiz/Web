require "test_helper"

class User::VerificationControllerTest < ActionDispatch::IntegrationTest
  test "can get pending page" do
    sign_in :one
    get user_verification_pending_path
    assert_response :success
  end

  test "redirect when already verified" do
    sign_in :one
    users(:one).update confirmed: true, confirmed_at: Time.now
    get user_verification_pending_path
    assert_redirected_to user_path
    assert_equal I18n.t("user.verification.pending.already_verified"), flash.notice
  end

  test "resend verification email" do
    sign_in :one
    assert_emails 1 do
      get user_verification_send_path
      assert_equal I18n.t("user.verification.pending.sent"), flash.notice
    end
  end

  test "do not resent verification email if already verified" do
    sign_in :one
    users(:one).update confirmed: true, confirmed_at: Time.now
    assert_emails 0 do
      get user_verification_send_path
      assert_equal I18n.t("user.verification.pending.already_verified"), flash.notice
    end
  end

  test "do not verify if token is invalid" do
    get user_verify_path("wrong token")
    assert_redirected_to user_verification_success_path(invalid: 1)
  end

  test "verification" do
    token = users(:one).signed_id expires_in: 1.day, purpose: :verify_email
    id = users(:one).id
    assert_changes -> { User.find(id).confirmed } do
      get user_verify_path(token)
      assert_in_delta Time.now, User.find(id).confirmed_at, 1.second
    end
  end

  test "verify unconfirmed email" do
    id = users(:one).id
    assert_changes -> { User.find(id).confirmed }, from: false, to: true do
      token = users(:one).signed_id expires_in: 1.day, purpose: :verify_email
      get user_verify_path(token)
    end
    assert_no_changes -> { User.find(id).email } do
      assert_emails 1 do
        users(:one).change({ email: "one@freequiz.ch" })
      end
      assert_not_nil User.find(id).unconfirmed_email
    end
    assert_changes -> { User.find(id).email } do
      token = users(:one).signed_id expires_in: 1.day, purpose: :verify_email
      get user_verify_path(token)
    end
  end
end
