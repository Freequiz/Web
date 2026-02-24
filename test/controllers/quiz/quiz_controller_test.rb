require "test_helper"

class Quiz::QuizControllerTest < ActionDispatch::IntegrationTest
  test "can view new quiz form" do
    sign_in :one
    get quiz_create_path
    assert_response :success
  end

  test "need to be logged in to view new quiz form" do
    get quiz_create_path
    assert_response :redirect
  end

  test "can not create quiz when not logged in" do
    post quiz_create_path
    assert_redirected_to user_login_path(gg: quiz_create_path)
  end

  test "can create quiz" do
    sign_in :one
    assert_difference "Quiz.count", 1 do
      post quiz_create_path, params: { quiz: {
        title: "Quiz",
        description: "Description",
        from: language_id("german"),
        to: language_id("french"),
        visibility: "public",
        translations_attributes: {
          0 => { word: "Baum", translation: "Arbre" }
        }
      } }
      assert_response :redirect
    end

    follow_redirect!
    assert_response :success
  end

  test "can get destroy token" do
    sign_in :one
    quiz = quizzes(:one)
    get quiz_request_destroy_path(quiz.uuid)
    assert_response :success
  end

  test "can not get destroy token for quiz you do not own" do
    sign_in :two
    get quiz_request_destroy_path(:one)
    assert_response :redirect
  end

  test "can not get destroy token when not logged in" do
    get quiz_request_destroy_path(:one)
    assert_response :redirect
  end

  test "can destroy quiz" do
    sign_in :one

    get quiz_request_destroy_path(quizzes(:one).uuid)
    assert_response :success

    assert_difference "Quiz.count", -1 do
      delete quiz_delete_path(quizzes(:one).uuid, assigns(:token))
      assert_response :redirect
    end
  end

  test "can not destroy quiz with wrong token" do
    sign_in :one
    assert_no_difference "Quiz.count" do
      delete quiz_delete_path(:one, "wrong token")
      assert_response :redirect
    end
  end

  test "can not destroy quiz you do not own" do
    sign_in :two
    token = quizzes(:one).signed_id expires_in: 1.day, purpose: :destroy_quiz
    assert_no_difference "Quiz.count" do
      delete quiz_delete_path(:one, token)
    end
  end

  test "can not destroy quiz with expired token" do
    sign_in :one
    token = quizzes(:one).signed_id expires_in: 0, purpose: :destroy_quiz
    assert_no_difference "Quiz.count" do
      delete quiz_delete_path(:one, token)
    end
  end

  test "can not destroy quiz when not logged in" do
    token = quizzes(:one).signed_id expires_in: 1.day, purpose: :destroy_quiz
    assert_no_difference "Quiz.count" do
      delete quiz_delete_path(:one, token)
    end
  end

  test "can view quiz edit" do
    sign_in :one
    get quiz_edit_path(:one)
    assert_response :success
  end

  test "can not view quiz edit page without being logged in" do
    get quiz_edit_path(:one)
    assert_response :redirect
  end

  test "can not view quiz edit page for quiz you do not own" do
    sign_in :two
    get quiz_edit_path(:one)
    assert_response :redirect
  end

  test "can edit quiz" do
    sign_in :one
    assert_no_difference -> { quizzes(:one).reload.translations.count } do
      patch quiz_edit_path(:one), params: { quiz: {
        title: "New Title",
        description: "New Description",
        from: language_id("german"),
        to: language_id("french"),
        visibility: "public",
        translations_attributes: {
          0 => { id: translations(:one).id, word: "Baum", translation: "Arbre", _destroy: "0" },
          1 => { id: translations(:one1).id, word: "Baum", translation: "Arbre", _destroy: "0" }
        }
      } }
    end
    assert_redirected_to quiz_show_path(:one)
    assert_equal "New Title", quizzes(:one).reload.title
  end

  test "can destroy translation" do
    sign_in :one
    assert_difference -> { quizzes(:one).reload.translations.count }, -1 do
      patch quiz_edit_path(:one), params: { quiz: {
        title: "New Title",
        description: "New Description",
        from: language_id("german"),
        to: language_id("french"),
        visibility: "public",
        translations_attributes: {
          0 => { id: translations(:one).id, word: "Tisch", translation: "Table", _destroy: "1" },
          1 => { id: translations(:one1).id, word: "Baum", translation: "Arbre", _destroy: "0" }
        }
      } }
      assert_redirected_to quiz_show_path(:one)
    end
  end

  test "can favorite a quiz" do
    sign_in :one
    quiz = quizzes(:two)
    assert_difference "FavoriteQuiz.count", 1 do
      patch quiz_favorite_path(quiz.uuid)
      assert_response :redirect
    end

    assert users(:one).favorite_quiz?(quiz)
  end

  test "can unfavorite a quiz" do
    sign_in :two
    quiz = quizzes(:two)
    assert_difference "FavoriteQuiz.count", -1 do
      patch quiz_favorite_path(quiz.uuid)
      assert_response :redirect
    end

    assert_not users(:two).favorite_quiz?(quiz)
  end

  test "can not favorite a quiz when not logged in" do
    patch quiz_favorite_path(:one)
    assert_redirected_to user_login_path(gg: quiz_favorite_path(:one))
  end

  test "can get quiz report form" do
    sign_in :one
    get quiz_report_path(:one)
    assert_response :success
  end

  test "can report a quiz" do
    sign_in :one
    assert_difference "QuizReport.count", 1 do
      assert_emails User.admins.count do
        post quiz_report_path(:one), params: { quiz_report: { reason: "reason", spam: "1" } }
        assert_response :redirect
      end
    end

    assert QuizReport.last.spam
  end
end
