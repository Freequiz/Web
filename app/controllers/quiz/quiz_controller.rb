class Quiz::QuizController < ApplicationController
  include ApiUtils

  before_action :require_login! do
    setup_locale "quiz.quiz"
  end

  before_action only: %i[show cards smart write multi] do
    override_action :show

    @access_token = generate_access_token(current_user, 31.days)

    @quiz = Quiz.find_by(uuid: params[:quiz_uuid])
    redirect_to root_path, notice: tp("not_found") unless @quiz.present? && @quiz.user_allowed_to_view?(current_user)
    redirect_to root_path, notice: tp("no_translations") unless @quiz.translations_count.positive?
  end

  def cards; end

  def smart; end

  def write; end

  def multi; end

  def favorite
    @quiz = Quiz.find_by(uuid: params[:quiz_uuid])
    return unless @quiz.present?

    if (favorite = @user.favorite_quizzes.find_by(quiz_id: @quiz.id)).present?
      favorite.destroy
    else
      @user.favorite_quizzes.create quiz_id: @quiz.id
    end

    redirect_to quiz_show_path
  end

  def new
    @quiz = @user.quizzes.new
    4.times { @quiz.translations.build }
  end

  def create
    override_action :new

    @quiz = @user.quizzes.new(quiz_params)
    if @quiz.save
      redirect_to quiz_show_path(@quiz.uuid), notice: tp("quiz_created")
    else
      flash.now.alert = @quiz.get_errors
      4.times { @quiz.translations.build } if @quiz.translations.count.zero?
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @quiz = Quiz.find_by(uuid: params[:quiz_uuid])

    return redirect_to root_path, notice: tp("not_found") unless @quiz.present?

    redirect_to root_path, alert: t("errors.not_allowed_to_view_quiz") unless @quiz.user_allowed_to_view? @user

    @learn_data = @quiz.learn_data(@user).sort_by { |t| t[:id] }
  end

  def request_destroy
    @quiz = @user.quizzes.find_by(uuid: params[:quiz_uuid])

    if @quiz.present?
      @token = @quiz.signed_id purpose: :destroy_quiz, expires_in: 1.day
    else
      redirect_to root_path
    end
  end

  def edit
    override_action "new"

    @quiz = @user.quizzes.find_by(uuid: params[:quiz_uuid])

    return redirect_to root_path, notice: tp("not_found") unless @quiz.present?

    4.times { @quiz.translations.build } unless @quiz.translations.count.positive?
  end

  def update
    override_action "new"

    @quiz = @user.quizzes.find_by(uuid: params[:quiz_uuid])

    redirect_to root_path, notice: tp("not_found") unless @quiz.present?

    if @quiz.update(quiz_params)
      redirect_to quiz_show_path(@quiz.uuid), notice: tp("saved")
    else
      flash.now.alert = @quiz.get_errors
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    quiz = Quiz.find_signed params[:destroy_token], purpose: :destroy_quiz

    return redirect_to root_path, notice: tp("not_found") unless quiz.present?

    if quiz.user == @user
      quiz.destroy
      flash.notice = tp("deleted")
    else
      flash.alert = tp("not_allowed")
    end
    redirect_to root_path
  end

  def new_report
    @quiz = Quiz.find_by uuid: params[:quiz_uuid]
    @quiz_report = QuizReport.new
  end

  def report
    @quiz = Quiz.find_by uuid: params[:quiz_uuid]
    @quiz_report = @quiz.quiz_reports.new(quiz_report_params)

    @quiz_report.user = @user if logged_in?

    if @quiz_report.save
      AdminMailer.with(quiz: @quiz, quiz_report: @quiz_report).new_quiz_report.deliver_later
      redirect_to quiz_show_path(@quiz_report.quiz.uuid), notice: t("quiz.quiz.report.saved")
    else
      flash.now.alert = t("quiz.quiz.report.failed")
      render :new_report, status: :unprocessable_entity
    end
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

  def quiz_report_params
    params.require(:quiz_report).permit(
      :description,
      :sexual,
      :violence,
      :hate,
      :spam,
      :child_abuse,
      :mobbing
    )
  end
end
