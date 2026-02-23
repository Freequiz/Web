require "test_helper"

class BanTest < ActionDispatch::IntegrationTest
    def get_routes
        [
            root_path,
            terms_of_service_path,
            privacy_policy_path,
            security_policy_path,
            sponsors_path,
            search_path,
            user_public_path(username: "one"),
            user_path,
            user_edit_path,
            user_quizzes_path,
            user_favorites_path,
            user_library_path,
            user_settings_path,
            user_delete_path
        ]
    end

    test "can visit routes" do
        sign_in :one

        get_routes.each do |route|
            get route
            assert_response :success
        end
    end

    test "cannot visit routes when banned" do
        sign_in :admin

        assert_changes -> { users(:one).reload.banned? }, from: false, to: true do
            patch admin_user_ban_url(users(:one).username), params: { user: { banned: true, ban_reason: "test" } }
            assert_equal "User banned", flash[:notice]
            assert_equal "test", users(:one).reload.ban_reason
        end

        sign_in :one

        get_routes.each do |route|
            get route
            assert_response :unauthorized
        end
    end
end
