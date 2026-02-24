require "test_helper"

class Api::BugReportControllerTest < ActionDispatch::IntegrationTest
  test "create bug report" do
    assert_changes "BugReport.count" do
      put api_bug_create_path, headers: api_sign_in(:confirmed), params: {
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

  test "cannot create bug report with too long title" do
    assert_no_changes "BugReport.count" do
      put api_bug_create_path, headers: api_sign_in(:confirmed), params: {
        bug_report: {
          title: "a" * 256,
          body: "Test",
          url: "http://example.com",
          platform: "Test",
          user_agent: "Test"
        }
      }
      assert_response :unprocessable_entity
      errors = @response.parsed_body.symbolize_keys[:errors]
      assert_equal 1, errors.length
      assert_equal "too_long", errors["title"][0]["error"]
    end
  end

  test "cannot create bug report if email is not verified" do
    assert_no_changes "BugReport.count" do
      put api_bug_create_path, headers: api_sign_in(:one), params: {
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
