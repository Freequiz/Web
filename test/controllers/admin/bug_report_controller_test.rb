require "test_helper"

class Admin::BugReportControllerTest < ActionDispatch::IntegrationTest
  test "can create a bug report" do
    sign_in :confirmed

    assert_difference "BugReport.count", 1 do
      post bug_report_path, params: { bug_report: { title: "Test", body: "Test", created_from: root_path } }
      assert_redirected_to root_path
    end
  end

  test "cannot create a bug report if email is not verified" do
    sign_in :one

    assert_no_difference "BugReport.count" do
      post bug_report_path, params: { bug_report: { title: "Test", body: "Test", created_from: root_path } }
      assert_redirected_to root_path
    end
  end

  test "cannot create a bug report if not signed in" do
    assert_no_difference "BugReport.count" do
      post bug_report_path, params: { bug_report: { title: "Test", body: "Test", created_from: root_path } }
      assert_response :redirect
    end
  end

  test "can get triage" do
    sign_in :admin

    get admin_bug_triage_path
    assert_response :redirect

    follow_redirect!
    assert_response :success
  end

  test "cannot get triage if not signed in" do
    get admin_bug_triage_path
    assert_response :not_found
  end

  test "cannot get triage if not admin" do
    sign_in :one

    get admin_bug_triage_path
    assert_response :not_found
  end

  test "cannot get triage show if not signed in" do
    get admin_bug_triage_show_path(bug_reports(:one))
    assert_response :not_found
  end

  test "cannot get triage show if not admin" do
    sign_in :one

    get admin_bug_triage_show_path(bug_reports(:one))
    assert_response :not_found
  end

  test "can get triage show" do
    sign_in :admin

    get admin_bug_triage_show_path(bug_reports(:one))
    assert_response :success
  end

  test "can verdict triage" do
    sign_in :admin

    patch admin_bug_triage_show_path(bug_reports(:one)), params: { bug_report: { status: "open" } }
    assert_redirected_to admin_bug_triage_path

    assert_equal "open", bug_reports(:one).reload.status

    follow_redirect!
    assert_redirected_to admin_bug_triage_show_path(bug_reports(:two))

    follow_redirect!
    assert_response :success
  end

  test "cannot verdict triage if not signed in" do
    patch admin_bug_triage_show_path(bug_reports(:one)), params: { bug_report: { status: "open" } }
    assert_response :not_found
  end

  test "cannot verdict triage if not admin" do
    sign_in :one

    assert_no_changes -> { bug_reports(:one).reload.status } do
      patch admin_bug_triage_show_path(bug_reports(:one)), params: { bug_report: { status: "open" } }
      assert_response :not_found
    end
  end

  test "can get list" do
    sign_in :admin

    get admin_bugs_path
    assert_response :success
  end

  test "cannot get list if not signed in" do
    get admin_bugs_path
    assert_response :not_found
  end

  test "cannot get list if not admin" do
    sign_in :one

    get admin_bugs_path
    assert_response :not_found
  end

  test "can get show" do
    sign_in :admin

    get admin_bug_path(bug_reports(:one))
    assert_response :success
  end

  test "cannot get show if not signed in" do
    get admin_bug_path(bug_reports(:one))
    assert_response :not_found
  end

  test "cannot get show if not admin" do
    sign_in :one

    get admin_bug_path(bug_reports(:one))
    assert_response :not_found
  end

  test "can update status" do
    sign_in :admin

    patch admin_bug_status_path(bug_reports(:one)), params: { bug_report: { status: "open" } }
    assert_redirected_to admin_bug_path(bug_reports(:one))

    assert_equal "open", bug_reports(:one).reload.status
  end

  test "cannot update status if not signed in" do
    assert_no_changes -> { bug_reports(:one).reload.status } do
      patch admin_bug_status_path(bug_reports(:one)), params: { bug_report: { status: "open" } }
      assert_response :not_found
    end
  end

  test "cannot update status if not admin" do
    sign_in :one

    assert_no_changes -> { bug_reports(:one).reload.status } do
      patch admin_bug_status_path(bug_reports(:one)), params: { bug_report: { status: "open" } }
      assert_response :not_found
    end
  end
end
