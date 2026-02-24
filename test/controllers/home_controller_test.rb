require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "can get root" do
    get root_url
    assert_response :success
  end

  test "can get root when signed in" do
    sign_in :one
    get root_url
    assert_response :success
  end

  test "can get sponsors" do
    get sponsors_url
    assert_response :success
  end

  test "can get terms of service" do
    get terms_of_service_url
    assert_response :success
  end

  test "can get privacy policy" do
    get privacy_policy_url
    assert_response :success
  end

  test "can get security policy" do
    get security_policy_url
    assert_response :success
  end

  test "can search quizzes" do
    get search_url
    assert_response :success
  end
end
