require "test_helper"

class Api::DocsControllerTest < ActionDispatch::IntegrationTest
  test "docs viewing permission" do
    pathes = [
      api_docs_path,
      api_docs_users_path,
      api_docs_quizzes_path,
      api_docs_authentication_path,
      api_docs_general_errors_path,
      api_docs_bugs_path,
      api_docs_languages_path
    ]

    pathes.each do |path|
      get path
      assert_response :not_found
    end

    sign_in :admin

    pathes.each do |path|
      get path
      assert_response :success
    end
  end
end
