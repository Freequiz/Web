require "test_helper"

class BugReportTest < ActiveSupport::TestCase
  test "can create a bug report" do
    bug_report = BugReport.create
    assert bug_report
    assert_equal "new", bug_report.status
  end

  test "can change bug report status" do
    bug_report = BugReport.create
    assert_equal "new", bug_report.status
    bug_report.update(status: "open")
    assert_equal "open", bug_report.status
  end

  test "can get bug report title" do
    bug_report = BugReport.create(title: "Test")
    assert_equal "Test", bug_report.get_title
  end

  test "can get an empty field" do
    bug_report = BugReport.create
    assert_equal "Not defined", bug_report.get(:title)
  end
end
