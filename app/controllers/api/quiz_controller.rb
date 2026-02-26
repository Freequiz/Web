class Api::QuizController < ApplicationController
  include ApiUtils

  protect_from_forgery with: :null_session
  around_action :locale_en
  skip_before_action :setup_login
  skip_around_action :switch_locale

  before_action :api_require_valid_access_token!, except: %i[data search score sync_score reset_score]
  before_action :api_ajax_require_valid_access_token!, only: %i[score sync_score reset_score]

  def search
    query = ActiveRecord::Base.connection.quote(params[:query])
    page = params[:page] || 1
    offset = (page.to_i * 50) - 50
    next_page = Quiz.count > offset + 50
    quizzes =
      Quiz.find_by_sql(
        "SELECT * FROM quizzes WHERE visibility = 'public' ORDER BY SIMILARITY(title, #{query}) DESC LIMIT 50 OFFSET #{offset}"
      )

    render json: { success: true, next_page:, data: quizzes.map { |q| q.data(@api_user) } }
  end

  def create
    unless validate_params(
      :title,
      :from,
      :to,
      :visibility,
      hash: quiz_params
    )
      return(
          json(
            {
              success: false,
              token: "fields.missing",
              message: "Missing title, from, to or visibility"
            },
            :bad_request
          )
        )
    end

    @quiz = @api_user.quizzes.new(quiz_params)

    unless @quiz.valid?
      return(
          json(
            {
              success: false,
              token: "record.invalid",
              errors: @quiz.errors.details,
              message: "Some parameters don't meet requirements"
            },
            :bad_request
          )
        )
    end

    unless @quiz.save
      return(
          json(
            {
              success: false,
              token: "record.invalid",
              errors: @quiz.errors.details,
              message: "Something went wrong whilst creating the quiz"
            },
            :unprocessable_entity
          )
        )
    end

    render nothing: true, status: :created
  end

  def data
    unless (@quiz = Quiz.find_by(uuid: params[:quiz_id])).present?
      return(
          json(
            {
              success: false,
              token: "quiz.notfound",
              message: "Quiz doesn't exist"
            },
            :not_found
          )
        )
    end
    return if @quiz.user_allowed_to_view? api_current_user

    json(
      {
        success: false,
        token: "user.notallowed",
        message: "User is not allowed to view Quiz"
      },
      :unauthorized
    )
  end

  def request_destroy
    unless (quiz = Quiz.find_by(uuid: params[:quiz_id])).present?
      return(
          json(
            {
              success: false,
              token: "quiz.notfound",
              message: "Quiz doesn't exist"
            },
            :not_found
          )
        )
    end
    unless quiz.user == @api_user
      return(
          json(
            {
              success: false,
              token: "user.notallowed",
              message: "User is not allowed to manage this Quiz"
            },
            :unauthorized
          )
        )
    end

    token = quiz.signed_id purpose: :destroy_quiz, expires_in: 1.day
    json({ success: true, token:, expire: 1.day.from_now.to_i })
  end

  def destroy
    unless (quiz = Quiz.find_signed(params[:destroy_token], purpose: :destroy_quiz)).present?
      return(
          json(
            {
              success: false,
              token: "quiz.notfound",
              message: "Quiz doesn't exist"
            },
            :not_found
          )
        )
    end
    unless quiz.user == @api_user
      return(
          json(
            {
              success: false,
              token: "user.notallowed",
              message: "User is not allowed to manage this Quiz"
            },
            :unauthorized
          )
        )
    end

    quiz.destroy
    json({ success: true, message: "Quiz deleted" })
  end

  def update
    unless (@quiz = @api_user.quizzes.find_by(uuid: params[:quiz_id])).present?
      return(
          json(
            {
              success: false,
              token: "quiz.notfound",
              message: "Quiz doesn't exist or is not owned by user"
            },
            :not_found
          )
        )
    end

    unless @quiz.update(quiz_params)
      return(
          json(
            {
              success: false,
              token: "record.invalid",
              errors: @quiz.errors.details,
              message: "Something went wrong whilst saving the Quiz"
            },
            :bad_request
          )
        )
    end

    render nothing: true, status: :accepted
  end

  def score
    unless (quiz = Quiz.find_by(uuid: params[:quiz_id])).present?
      return(
          json(
            {
              success: false,
              token: "quiz.notfound",
              message: "Quiz doesn't exist"
            },
            :not_found
          )
        )
    end

    score = @api_user.scores.find(params[:score_id])
    return json({ success: false, token: "relation.mismatch", message: "Score does not belong to specified quiz" }, :bad_request) unless score.translation.quiz_id == quiz.id

    return json({ success: false, token: "fields.invalid", message: "Invalid mode" }, :bad_request) unless Score::MODES.include?(params[:mode].to_sym)

    unless params[:score].present?
      return(
          json(
            { success: false, token: "fields.missing", message: "Missing score" },
            :bad_request
          )
        )
    end

    score.update params[:mode].to_sym => params[:score]

    json({ success: true, message: "Score updated", updated_data: quiz.learn_data(@api_user) }, :accepted)
  end

  def sync_score
    unless (@quiz = Quiz.find_by(uuid: params[:quiz_id])).present?
      return(
          json(
            {
              success: false,
              token: "quiz.notfound",
              message: "Quiz doesn't exist"
            },
            :not_found
          )
        )
    end

    @quiz.sync_score sync_score_params, @api_user
    render :data, status: :accepted
  end

  def reset_score
    unless (quiz = Quiz.find_by(uuid: params[:quiz_id])).present?
      return(
          json(
            {
              success: false,
              token: "quiz.notfound",
              message: "Quiz doesn't exist"
            },
            :not_found
          )
        )
    end

    return json({ success: false, token: "fields.invalid", message: "Mode is invalid" }, :bad_request) unless Score::MODES.include? params[:mode].to_sym

    @api_user.scores.joins(:translation).where("translation.quiz_id": quiz.id).update_all params[:mode] => 0

    json(
      {
        success: true,
        message: "Score was reset for mode #{params[:mode].downcase}",
        updated_data: quiz.learn_data(@api_user)
      },
      :accepted
    )
  end

  def favorite
    unless (quiz = Quiz.find_by(uuid: params[:quiz_id])).present?
      return(
          json(
            {
              success: false,
              token: "quiz.notfound",
              message: "Quiz doesn't exist"
            },
            :not_found
          )
        )
    end

    score = @api_user.scores.find(params[:score_id])

    return json({ success: false, token: "score.notfound", message: "Score doesn't exist" }, :not_found) unless score.present?

    return json({ success: false, token: "relation.mismatch", message: "Score does not belong to specified quiz" }, :bad_request) unless score.translation.quiz_id == quiz.id

    score.update favorite: params[:favorite]

    json({ success: true, message: "Favorites updated", updated_data: quiz.learn_data(@api_user) }, :accepted)
  end

  def favorite_quiz
    unless (quiz = Quiz.find_by(uuid: params[:quiz_id])).present?
      return(
          json(
            {
              success: false,
              token: "quiz.notfound",
              message: "Quiz doesn't exist"
            },
            :not_found
          )
        )
    end

    if params[:favorite]
      @api_user.favorite_quizzes.create quiz_id: quiz.id unless @api_user.favorite_quiz?(quiz)
    else
      favorite_quiz = @api_user.favorite_quizzes.find_by(quiz_id: quiz.id)
      favorite_quiz.destroy if favorite_quiz.present?
    end

    json({ success: true, message: @api_user.favorite_quiz?(quiz) ? "Quiz was added to favorites" : "Quiz is no longer a favorite", favorite: @api_user.favorite_quiz?(quiz) }, :accepted)
  end

  def report
    quiz = Quiz.find_by(uuid: params[:quiz_id])

    return render "api/bug_report/not_verified", status: :unauthorized unless @api_user.verified?

    return json({ success: false, token: "quiz.notfound", message: "Quiz doesn't exist" }, :not_found) unless quiz.present?

    report = quiz.quiz_reports.new quiz_report_params
    report.user = @api_user
    if report.save
      AdminMailer.with(quiz: quiz, quiz_report: report).new_quiz_report.deliver_later
      json({ success: true, message: "Quiz reported" }, :created)
    else
      json({ success: false, token: "record.invalid", message: "Record invalid", errors: report.errors.full_messages }, :unprocessable_entity)
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

  def sync_score_params
    params.require(:quiz).permit(
      :favorite,
      {
        data: [
          :score_id,
          :favorite,
          :updated,
          {
            score: %i[cards multi write smart]
          }
        ]
      }
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
