require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
    test "should get user list" do
        sign_in :admin

        get admin_users_url
        assert_response :success
    end

    test "can not get user list if not admin" do
        sign_in :one

        get admin_users_url
        assert_response :not_found
    end

    test "can not get user list if not signed in" do
        get admin_users_url
        assert_response :not_found
    end

    test "should get user edit" do
        sign_in :admin

        get admin_user_edit_url(users(:one).username)
        assert_response :success
    end

    test "can not get user edit if not admin" do
        sign_in :one

        get admin_user_edit_url(users(:one).username)
        assert_response :not_found
    end

    test "can not get user edit if not signed in" do
        get admin_user_edit_url(users(:one).username)
        assert_response :not_found
    end

    test "cannot update user if not admin" do
        sign_in :one

        assert_emails 0 do
            assert_no_changes -> { users(:one).reload.email } do
                patch admin_user_edit_url(users(:one).username), params: { user: { email: "abc@wow.ch" } }
                assert_response :not_found
            end
        end
    end

    test "cannot update user if not signed in" do
        assert_emails 0 do
            assert_no_changes -> { users(:one).reload.email } do
                patch admin_user_edit_url(users(:one).username), params: { user: { email: "abc@wow.ch" } }
                assert_response :not_found
            end
        end
    end

    test "can confirm user" do
        sign_in :admin

        assert_emails 0 do
            assert_changes -> { users(:one).reload.verified? } do
                patch admin_user_edit_url(users(:one).username), params: { user: { confirmed: true, email: users(:one).email } }
                assert_in_delta Time.now, users(:one).reload.confirmed_at, 1.seconds
                assert_equal "Saved user", flash[:notice]
            end
        end
    end

    test "can unconfirm user" do
        sign_in :admin

        assert_emails 1 do
            assert_changes -> { users(:confirmed).reload.verified? } do
                patch admin_user_edit_url(users(:confirmed).username), params: { user: { confirmed: false, email: users(:confirmed).email } }
                assert_equal "Saved user and verification E-mail was sent", flash[:notice]
            end
        end
    end

    test "can change email" do
        sign_in :admin

        assert_emails 1 do
            assert_changes -> { users(:one).reload.email }, from: "one@one.one", to: "one1@freequiz.ch" do
                patch admin_user_edit_url(users(:one).username), params: { user: { email: "one1@freequiz.ch" } }
                assert_equal "Saved user and verification E-mail was sent", flash[:notice]
            end
        end
    end

    test "can change username" do
        sign_in :admin

        assert_emails 0 do
            assert_changes -> { users(:one).reload.username }, from: "one", to: "one1" do
                patch admin_user_edit_url(users(:one).username), params: { user: { username: "one1", email: users(:one).email } }
                assert_equal "Saved user", flash[:notice]
            end
        end
    end

    test "can change role" do
        sign_in :admin

        assert_emails 0 do
            assert_changes -> { users(:one).reload.role }, from: "user", to: "admin" do
                patch admin_user_edit_url(users(:one).username), params: { user: { role: "admin", email: users(:one).email } }
                assert_equal "Saved user", flash[:notice]
            end
        end
    end

    test "can get ban form" do
        sign_in :admin

        assert_no_changes -> { users(:one).reload.banned? } do
            get admin_user_ban_url(users(:one).username)
            assert_response :success
        end
    end

    test "cannot get ban form if not admin" do
        sign_in :one

        assert_no_changes -> { users(:one).reload.banned? } do
            get admin_user_ban_url(users(:one).username)
            assert_response :not_found
        end
    end

    test "cannot get ban form if not signed in" do
        assert_no_changes -> { users(:one).reload.banned? } do
            get admin_user_ban_url(users(:one).username)
            assert_response :not_found
        end
    end

    test "can ban user" do
        sign_in :admin

        assert_changes -> { users(:one).reload.banned? }, from: false, to: true do
            patch admin_user_ban_url(users(:one).username), params: { user: { banned: true, ban_reason: "test" } }
            assert_equal "User banned", flash[:notice]
            assert_equal "test", users(:one).reload.ban_reason
        end
    end

    test "cannot ban user if not admin" do
        sign_in :one

        assert_no_changes -> { users(:one).reload.banned? } do
            patch admin_user_ban_url(users(:one).username), params: { user: { banned: true, ban_reason: "test" } }
            assert_response :not_found
        end
    end

    test "cannot ban user if not signed in" do
        assert_no_changes -> { users(:one).reload.banned? } do
            patch admin_user_ban_url(users(:one).username), params: { user: { banned: true, ban_reason: "test" } }
            assert_response :not_found
        end
    end

    test "can unban user" do
        sign_in :admin

        assert_changes -> { users(:banned).reload.banned? }, from: true, to: false do
            patch admin_user_unban_url(users(:banned).username)
            assert_equal "User unbanned", flash[:notice]
        end
    end

    test "cannot unban user if not admin" do
        sign_in :one

        assert_no_changes -> { users(:banned).reload.banned? } do
            patch admin_user_unban_url(users(:banned).username)
            assert_response :not_found
        end
    end

    test "cannot unban user if not signed in" do
        assert_no_changes -> { users(:banned).reload.banned? } do
            patch admin_user_unban_url(users(:banned).username)
            assert_response :not_found
        end
    end

    test "cannot ban ip if not admin" do
        sign_in :one

        assert_no_changes "BannedIp.count" do
            patch admin_ban_ip_url, params: { banned_ip: { ip: "1.2.3.4", reason: "test" }, return: admin_users_url }
        end
    end

    test "cannot ban ip if not signed in" do
        assert_no_changes "BannedIp.count" do
            patch admin_ban_ip_url, params: { banned_ip: { ip: "1.2.3.4", reason: "test" }, return: admin_users_url }
        end
    end

    test "cannot unban ip which was not banned" do
        sign_in :admin

        assert_no_changes "BannedIp.count" do
            delete admin_ban_ip_url, params: { ip: "8.8.8.8", return: admin_users_url }
            assert_redirected_to admin_users_url
        end
    end

    test "cannot unban ip if not admin" do
        sign_in :one

        assert_no_changes "BannedIp.count" do
            delete admin_ban_ip_url, params: { ip: banned_ips(:one).ip, return: admin_users_url }
            assert_response :not_found
        end
    end

    test "cannot unban ip if not signed in" do
        assert_no_changes "BannedIp.count" do
            delete admin_ban_ip_url, params: { ip: banned_ips(:one).ip, return: admin_users_url }
            assert_response :not_found
        end
    end

    test "can get destroy token" do
        sign_in :admin

        assert_no_changes "User.count" do
            get admin_user_delete_url(users(:one).username)
            assert_response :success
        end
    end

    test "cannot get destroy token if not admin" do
        sign_in :one

        assert_no_changes "User.count" do
            get admin_user_delete_url(users(:one).username)
            assert_response :not_found
        end
    end

    test "cannot get destroy token if not signed in" do
        assert_no_changes "User.count" do
            get admin_user_delete_url(users(:one).username)
            assert_response :not_found
        end
    end

    test "can destroy user" do
        sign_in :admin

        assert_changes "User.count", -1 do
            get admin_user_delete_url(users(:one).username)
            assert_response :success

            delete admin_user_delete_url(users(:one).username, destroy_token: assigns(:token))
            assert_redirected_to admin_users_url
        end
    end

    test "cannot destroy user if not admin" do
        sign_in :one

        assert_no_changes "User.count" do
            token = users(:one).signed_id purpose: :destroy_user, expires_in: 1.day

            delete admin_user_delete_url(users(:one).username, destroy_token: token)
            assert_response :not_found
        end
    end

    test "cannot destroy user if not signed in" do
        assert_no_changes "User.count" do
            token = users(:one).signed_id purpose: :destroy_user, expires_in: 1.day

            delete admin_user_delete_url(users(:one).username, destroy_token: token)
            assert_response :not_found
        end
    end

    test "can send verification email" do
        sign_in :admin

        assert_emails 1 do
            get admin_user_send_verification_url(users(:one).username)
            assert_redirected_to admin_user_edit_url(users(:one).username)
        end
    end

    test "cannot send verification email if already verified" do
        sign_in :admin

        assert_emails 0 do
            get admin_user_send_verification_url(users(:confirmed).username)
            assert_redirected_to admin_user_edit_url(users(:confirmed).username)
        end
    end

    test "cannot send verification email if not admin" do
        sign_in :one

        assert_emails 0 do
            get admin_user_send_verification_url(users(:one).username)
            assert_response :not_found
        end
    end

    test "cannot send verification email if not signed in" do
        assert_emails 0 do
            get admin_user_send_verification_url(users(:one).username)
            assert_response :not_found
        end
    end

    test "can send password reset email" do
        sign_in :admin

        assert_emails 1 do
            get admin_user_send_password_reset_url(users(:one).username)
            assert_redirected_to admin_user_edit_url(users(:one).username)
        end
    end

    test "cannot send password reset email if not admin" do
        sign_in :one

        assert_emails 0 do
            get admin_user_send_password_reset_url(users(:one).username)
            assert_response :not_found
        end
    end

    test "cannot send password reset email if not signed in" do
        assert_emails 0 do
            get admin_user_send_password_reset_url(users(:one).username)
            assert_response :not_found
        end
    end

    test "can get prepare email" do
        sign_in :admin

        get admin_user_send_email_url(users(:one).username)
        assert_response :success
    end

    test "cannot get prepare email if not admin" do
        sign_in :one

        get admin_user_send_email_url(users(:one).username)
        assert_response :not_found
    end

    test "cannot get prepare email if not signed in" do
        get admin_user_send_email_url(users(:one).username)
        assert_response :not_found
    end

    test "can send email" do
        sign_in :admin

        assert_emails 1 do
            post admin_user_send_email_url(users(:one).username), params: { email: { subject: "test", body: "test" } }
            assert_redirected_to admin_user_edit_url(users(:one).username)
        end
    end

    test "cannot send email if not admin" do
        sign_in :one

        assert_emails 0 do
            post admin_user_send_email_url(users(:one).username), params: { email: { subject: "test", body: "test" } }
            assert_response :not_found
        end
    end

    test "cannot send email if not signed in" do
        assert_emails 0 do
            post admin_user_send_email_url(users(:one).username), params: { email: { subject: "test", body: "test" } }
            assert_response :not_found
        end
    end
end
