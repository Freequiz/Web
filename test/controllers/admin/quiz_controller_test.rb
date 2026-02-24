require "test_helper"

class Admin::QuizControllerTest < ActionDispatch::IntegrationTest
  test "view quiz triage" do
    sign_in :admin
    get admin_quiz_report_triage_path
    assert_response :success
  end

  test "cannot view triage if not logged in" do
    get admin_quiz_report_triage_path
    assert_response :not_found
  end

  test "cannot view triage if not admin" do
    sign_in :one
    get admin_quiz_report_triage_path
    assert_response :not_found
  end

  test "quiz destroy request" do
    sign_in :admin

    get admin_quiz_request_delete_path(quiz_id: quizzes(:one).uuid)
    assert_response :success
  end

  test "cannot request destroy if not logged in" do
    get admin_quiz_request_delete_path(quiz_id: quizzes(:one).uuid)
    assert_response :not_found
  end

  test "cannot request destroy if not admin" do
    sign_in :one
    get admin_quiz_request_delete_path(quiz_id: quizzes(:one).uuid)
    assert_response :not_found
  end

  test "can destroy quiz" do
    sign_in :admin

    quiz = quizzes(:one)

    get admin_quiz_request_delete_path(quiz_id: quiz.uuid)
    assert_response :success

    assert_difference "Quiz.count", -1 do
      delete admin_quiz_delete_path(delete_token: assigns(:destroy_token), quiz_id: quiz.id)
      assert_response :redirect
      assert_equal "Quiz was destroyed", flash[:notice]
    end
  end

  test "cannot destroy quiz if not logged in" do
    quiz = quizzes(:one)
    token = quiz.signed_id expires_in: 1.hour, purpose: :admin_destroy

    assert_no_difference "Quiz.count" do
      delete admin_quiz_delete_path(delete_token: token, quiz_id: quiz.id)
      assert_response :not_found
    end
  end

  test "cannot destroy quiz if not admin" do
    sign_in :one

    quiz = quizzes(:one)
    token = quiz.signed_id expires_in: 1.hour, purpose: :admin_destroy

    assert_no_difference "Quiz.count" do
      delete admin_quiz_delete_path(delete_token: token, quiz_id: quiz.id)
      assert_response :not_found
    end
  end

  test "cannot destroy quiz with invalid token" do
    sign_in :admin

    quiz = quizzes(:one)

    assert_no_difference "Quiz.count" do
      delete admin_quiz_delete_path(delete_token: "invalid", quiz_id: quiz.id)
      assert_response :redirect
      assert_equal "Could not destroy Quiz. Token might have expired", flash[:alert]
    end
  end

  test "cannot destroy quiz with expired token" do
    sign_in :admin

    quiz = quizzes(:one)
    token = quiz.signed_id expires_in: 0, purpose: :admin_destroy

    assert_no_difference "Quiz.count" do
      delete admin_quiz_delete_path(delete_token: token, quiz_id: quiz.id)
      assert_response :redirect
      assert_equal "Could not destroy Quiz. Token might have expired", flash[:alert]
    end
  end

  test "triage quiz destroy" do
    sign_in :admin

    report = quiz_reports(:one)
    quiz = report.quiz

    get admin_quiz_request_delete_path(quiz_id: quiz.uuid, triage: report.id)
    assert_response :success

    assert_difference "Quiz.count", -1 do
      delete admin_quiz_delete_path(delete_token: assigns(:destroy_token), quiz_id: quiz.id, triage: report.id)
      assert_response :redirect
      assert_equal "Triage solved by deleting Quiz", flash[:notice]
    end
  end

  test "triage quiz destroy with expired token" do
    sign_in :admin

    report = quiz_reports(:one)
    quiz = report.quiz
    token = quiz.signed_id expires_in: 0, purpose: :admin_destroy

    assert_no_difference "Quiz.count" do
      delete admin_quiz_delete_path(delete_token: token, quiz_id: quiz.id, triage: report.id)
      assert_response :redirect
      assert_equal "Could not destroy Quiz. Token might have expired", flash[:alert]
    end
  end

  test "triage quiz destroy with invalid token" do
    sign_in :admin

    report = quiz_reports(:one)
    quiz = report.quiz

    assert_no_difference "Quiz.count" do
      delete admin_quiz_delete_path(delete_token: "invalid", quiz_id: quiz.id, triage: report.id)
      assert_response :redirect
      assert_equal "Could not destroy Quiz. Token might have expired", flash[:alert]
    end
  end

  test "triage destroy quiz if not logged in" do
    report = quiz_reports(:one)
    quiz = report.quiz
    token = quiz.signed_id expires_in: 1.hour, purpose: :admin_destroy

    assert_no_difference "Quiz.count" do
      delete admin_quiz_delete_path(delete_token: token, quiz_id: quiz.id, triage: report.id)
      assert_response :not_found
    end
  end

  test "triage destroy quiz if not admin" do
    sign_in :one

    report = quiz_reports(:one)
    quiz = report.quiz
    token = quiz.signed_id expires_in: 1.hour, purpose: :admin_destroy

    assert_no_difference "Quiz.count" do
      delete admin_quiz_delete_path(delete_token: token, quiz_id: quiz.id, triage: report.id)
      assert_response :not_found
    end
  end

  test "can ignore report" do
    sign_in :admin

    report = quiz_reports(:one)
    assert_equal "open", report.status

    post admin_quiz_report_ignore_triage_path(triage_id: report.id)
    assert_response :redirect
    assert_equal "Quiz report ignored", flash[:notice]

    report.reload

    assert_equal "ignored", report.status
  end

  test "cannot ignore report if not logged in" do
    report = quiz_reports(:one)
    assert_equal "open", report.status

    post admin_quiz_report_ignore_triage_path(triage_id: report.id)
    assert_response :not_found

    report.reload

    assert_equal "open", report.status
  end

  test "cannot ignore report if not admin" do
    sign_in :one

    report = quiz_reports(:one)
    assert_equal "open", report.status

    post admin_quiz_report_ignore_triage_path(triage_id: report.id)
    assert_response :not_found

    report.reload

    assert_equal "open", report.status
  end

  test "can view report" do
    sign_in :admin

    report = quiz_reports(:one)
    get admin_quiz_report_path(report.id)
    assert_response :success
  end

  test "cannot view report if not logged in" do
    report = quiz_reports(:one)
    get admin_quiz_report_path(report.id)
    assert_response :not_found
  end

  test "cannot view report if not admin" do
    sign_in :one

    report = quiz_reports(:one)
    get admin_quiz_report_path(report.id)
    assert_response :not_found
  end

  test "can view edit page" do
    sign_in :admin

    quiz = quizzes(:one)
    get admin_quiz_edit_path(quiz.uuid)
    assert_response :success
  end

  test "cannot view edit page if not logged in" do
    quiz = quizzes(:one)
    get admin_quiz_edit_path(quiz.uuid)
    assert_response :not_found
  end

  test "cannot view edit page if not admin" do
    sign_in :one

    quiz = quizzes(:one)
    get admin_quiz_edit_path(quiz.uuid)
    assert_response :not_found
  end

  test "can update quiz" do
    sign_in :admin

    quiz = quizzes(:one)
    post admin_quiz_update_path(quiz.uuid), params: { quiz: { title: "New title" } }
    assert_response :redirect
    assert_equal "Quiz updated as admin", flash[:notice]

    quiz.reload
    assert_equal "New title", quiz.title
  end

  test "cannot update quiz if not logged in" do
    quiz = quizzes(:one)
    post admin_quiz_update_path(quiz.uuid), params: { quiz: { title: "New title" } }
    assert_response :not_found

    quiz.reload
    assert_not_equal "New Title", quiz.title
  end

  test "cannot update quiz if not admin" do
    sign_in :one

    quiz = quizzes(:one)
    post admin_quiz_update_path(quiz.uuid), params: { quiz: { title: "New title" } }
    assert_response :not_found

    quiz.reload
    assert_not_equal "New Title", quiz.title
  end

  test "can update quiz with triage" do
    sign_in :admin

    report = quiz_reports(:one)
    quiz = report.quiz
    post admin_quiz_update_path(quiz.uuid, triage: report.id), params: { quiz: { title: "New title" } }
    assert_response :redirect
    assert_equal "Triage solved though edit", flash[:notice]

    quiz.reload
    assert_equal "New title", quiz.title
  end
end
