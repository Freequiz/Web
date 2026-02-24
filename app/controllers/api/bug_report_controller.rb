class Api::BugReportController < ApplicationController
  include ApiUtils

  protect_from_forgery with: :null_session
  before_action :api_require_valid_access_token!
  around_action :locale_en
  skip_before_action :setup_login
  skip_around_action :switch_locale

  def create
    report = api_current_user.bug_reports.new(bug_report_params)

    return json({ success: true, message: "Bug report created" }, :created) if report.save

    json(
      {
        success: false,
        token: "record.invalid",
        errors: report.errors.details,
        message: "Could not create bug report"
      },
      :unprocessable_entity
    )
  end

  private

  def bug_report_params
    params.require(:bug_report).permit(
      :title,
      :body,
      :url,
      :platform,
      :user_agent
    )
  end
end
