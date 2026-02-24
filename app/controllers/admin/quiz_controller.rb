class Admin::QuizController < ApplicationController
  around_action :locale_en
  before_action :require_admin!

  def edit
    @quiz = Quiz.find_by(uuid: params[:quiz_id])
    @update_url = params[:triage].present? ? admin_quiz_update_path(triage: params[:triage]) : admin_quiz_update_path
    @cancel_path = params[:triage].present? ? admin_quiz_report_triage_path : quiz_show_path(@quiz.uuid)
  end

  def update
    @quiz = Quiz.find_by(uuid: params[:quiz_id])

    redirect_to root_path, notice: "Quiz was not found" unless @quiz.present?

    if @quiz.update(quiz_params)
      if params[:triage].present?
        QuizReport.find(params[:triage]).update status: :solved
        redirect_to admin_quiz_report_triage_path, notice: "Triage solved though edit"
      else
        redirect_to quiz_show_path(@quiz.uuid), notice: "Quiz updated as admin"
      end
    else
      flash.now.alert = @quiz.get_errors
      render :edit, status: :unprocessable_entity
    end
  end

  def request_destroy
    @quiz = Quiz.find_by(uuid: params[:quiz_id])
    @destroy_token = @quiz.signed_id purpose: :admin_destroy, expires_in: 1.hour
    @destroy_path = params[:triage].present? ? admin_quiz_delete_path(delete_token: @destroy_token, triage: params[:triage]) : admin_quiz_delete_path(delete_token: @destroy_token)
    @cancel_path = params[:triage].present? ? admin_quiz_report_triage_path : quiz_show_path(@quiz.uuid)
  end

  def destroy
    quiz = Quiz.find_signed(params[:delete_token], purpose: :admin_destroy)

    if quiz.present?
      quiz.destroy
      if params[:triage].present?
        QuizReport.find(params[:triage]).update status: :deleted
        redirect_to admin_quiz_report_triage_path, notice: "Triage solved by deleting Quiz"
      else
        redirect_to root_path, notice: "Quiz was destroyed"
      end
    elsif params[:triage].present?
      redirect_to admin_quiz_report_triage_path, alert: "Could not destroy Quiz. Token might have expired"
    else
      redirect_to quiz_show_path(params[:quiz_id]), alert: "Could not destroy Quiz. Token might have expired"
    end
  end

  def show_report
    @report = QuizReport.find(params[:quiz_report_id])
    @reported_quiz = @report.quiz
    reports = QuizReport::KEYS.filter { |k| @report[k] }
    @reported_for = reports.map { |s| s.to_s.gsub("_", " ").capitalize }.join(", ")

    render :triage if @report.status == "open"
  end

  def triage
    @report = QuizReport.order(created_at: :asc).where(status: :open).first

    return unless @report.present?

    @reported_quiz = @report.quiz
    reports = QuizReport::KEYS.filter { |k| @report[k] }
    @reported_for = reports.map { |s| s.to_s.gsub("_", " ").capitalize }.join(", ")
  end

  def ignore_triage
    QuizReport.find(params[:triage_id]).update status: :ignored
    redirect_to admin_quiz_report_triage_path, notice: "Quiz report ignored"
  end

  private

  def quiz_params
    params.require(:quiz).permit(
      :title,
      :description,
      :from,
      :to,
      :visibility,
      translations_attributes: %i[id word translation _destroy]
    )
  end
end
