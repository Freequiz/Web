class Api::BugReportController < ApplicationController
  include ApiUtils

  protect_from_forgery with: :null_session
  before_action :api_require_valid_access_token!
  around_action :locale_en
  skip_before_action :setup_login
  skip_around_action :switch_locale

  def create
    return render :not_verified, status: :unauthorized unless api_current_user.verified?

    @report = api_current_user.bug_reports.new(bug_report_params)
    if @report.save
      render :bug_created, status: :created
    else
      render :bug_creation_error, status: :unprocessable_entity
    end
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
