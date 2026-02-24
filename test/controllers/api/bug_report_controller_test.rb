require "test_helper"

class Api::BugReportControllerTest < ActionDispatch::IntegrationTest
  test "create bug report" do
    assert_changes "BugReport.count" do
      put api_bug_create_path, headers: api_sign_in(:one), params: {
        bug_report: {
          title: "Test",
          body: "Test",
          url: "http://example.com",
          platform: "Test",
          user_agent: "Test"
        }
      }
      assert_response :success
    end
  end

  test "cannot create bug report when not logged in" do
    assert_no_changes "BugReport.count" do
      put api_bug_create_path, params: {
        bug_report: {
          title: "Test",
          body: "Test",
          url: "http://example.com",
          platform: "Test",
          user_agent: "Test"
        }
      }
      assert_response :unauthorized
    end
  end
end
