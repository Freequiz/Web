class Admin::BugReportController < ApplicationController
  before_action :require_admin!, except: :create
  before_action :require_login!
  before_action { setup_locale "bug_report" }

  before_action only: %i[show status] do
    @bug = BugReport.find_by(id: params[:bug_id])
    redirect_to admin_bugs_path(category: "new"), alert: "This bug report doesn't exist" unless @bug.present?
  end

  def create
    report = current_user.bug_reports.new(bug_report_params)
    if report.save
      flash.notice = tp("bug_report_created")
    else
      flash.alert =  tp("failed_to_create")
    end
    redirect_to bug_report_params[:created_from]
  end

  def triage
    triage_bug = BugReport.where(status: :new).order(created_at: :asc).first
    redirect_to admin_bug_triage_show_path(triage_bug) if triage_bug.present?
  end

  def triage_show
    @triage_bug = BugReport.find(params[:bug_report_id])
    redirect_to admin_bug_triage_path unless @triage_bug.present?
  end

  def triage_verdict
    triage_bug = BugReport.find(params[:bug_report_id])
    return redirect_to admin_bug_triage_path unless triage_bug.present?

    triage_bug.update status_params
    redirect_to admin_bug_triage_path
  end

  def list
    @category = params[:category] || "all"
    @category = BugReport::STATUSES.include?(@category) ? @category : "all"
    @bug_reports =
      (
            if @category == "all"
              BugReport.all.order(created_at: :desc)
            else
              BugReport.where(status: @category).order(created_at: :desc)
            end
          )
  end

  def show; end

  def status
    if @bug.update(status_params)
      flash.notice = "Status updated"
    else
      flash.alert =  "Status could not be updated"
    end
    redirect_to admin_bug_path(@bug.id)
  end

  private

  def bug_report_params
    params.require(:bug_report).permit(
      :title,
      :body,
      :steps,
      :url,
      :platform,
      :user_agent,
      :created_from,
      :ip,
      :request_method,
      :media_type,
      :post_parameters
    )
  end

  def status_params
    params.require(:bug_report).permit(:status)
  end
end
