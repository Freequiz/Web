class AdminMailer < ApplicationMailer
  default to: -> { User.admins.pluck(:email) }

  def new_quiz_report
    @quiz = params[:quiz]
    @quiz_report = params[:quiz_report]
    reporter = @quiz_report.user.present? ? " by #{params[:quiz_report].user.username}" : ""
    mail(subject: "Quiz #{@quiz.title} was reported#{reporter}")
  end
end
