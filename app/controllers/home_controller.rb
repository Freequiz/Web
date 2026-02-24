class HomeController < ApplicationController
  before_action { setup_locale "home" }

  def search
    results = Quiz.search_all_quizzes params
    @quizzes = results.first
    @pages = results.last
    @params = quiz_search_params
  end

  def root
    @new_quizzes = Quiz.where(visibility: "public").order(created_at: :desc).limit(5)

    return unless logged_in?

    @quizzes = @user.quizzes.order(created_at: :desc).limit(5)
  end

  def sponsors; end

  def terms_of_service
    @title = "Terms of Service | Freequiz"
  end

  def privacy_policy
    @title = "Privacy Policy | Freequiz"
  end

  def security_policy
    @title = "Security Policy | Freequiz"
  end

  private

  def quiz_search_params
    params.permit(:title, :sort, :commit, :page)
  end
end
