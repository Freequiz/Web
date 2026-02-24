require "test_helper"

class Api::QuizControllerTest < ActionDispatch::IntegrationTest
  test "can create quiz" do
    assert_difference "Quiz.count", 1 do
      assert_difference "Translation.count", 2 do
        put api_quiz_create_path, params: { quiz: {
          title: "Test Quiz",
          from: language_id(:german),
          to: language_id(:english),
          visibility: "public",
          translations_attributes: [
            { word: "Haus", translation: "House" },
            { word: "Katze", translation: "Cat" }
          ]
        } }, headers: api_sign_in(:one)
        assert_response :success
      end
    end
  end

  test "cannot create quiz when not logged in" do
    assert_no_difference "Quiz.count" do
      put api_quiz_create_path, params: { quiz: {
        title: "Test Quiz",
        from: language_id(:german),
        to: language_id(:english),
        visibility: "public",
        translations_attributes: [
          { word: "Haus", translation: "House" },
          { word: "Katze", translation: "Cat" }
        ]
      } }
      assert_response :unauthorized
    end
  end

  test "can search for quizzes" do
    get api_quiz_search_path, params: { query: "MyStrin" }
    assert_response :success
    assert_equal "MyString", @response.parsed_body["data"].first["title"]
  end

  test "can get quiz data" do
    get api_quiz_data_path(quizzes(:two).uuid)
    assert_response :success
    assert_equal "MyString", @response.parsed_body["quiz_data"]["title"]
  end

  test "can view hidden quiz" do
    get api_quiz_data_path(quizzes(:hidden).uuid)
    assert_response :success
  end

  test "owner can view private quiz" do
    get api_quiz_data_path(quizzes(:private).uuid), headers: api_sign_in(:one)
    assert_response :success
  end

  test "cannot view private quiz" do
    get api_quiz_data_path(quizzes(:private).uuid), headers: api_sign_in(:two)
    assert_response :unauthorized
  end

  test "cannot view private quiz when not logged in" do
    get api_quiz_data_path(quizzes(:private).uuid)
    assert_response :unauthorized
  end

  test "can report quiz" do
    assert_difference "QuizReport.count", 1 do
      assert_emails User.where(role: "admin").count do
        post api_quiz_report_path(quizzes(:two).uuid), params: { quiz_report: { spam: 1 } }, headers: api_sign_in(:confirmed)
        assert_response :success
        assert_equal quizzes(:two), QuizReport.last.quiz
      end
    end
  end

  test "cannot report quiz when not logged in" do
    assert_no_difference "QuizReport.count" do
      assert_emails 0 do
        post api_quiz_report_path(quizzes(:two).uuid), params: { quiz_report: { spam: 1 } }
        assert_response :unauthorized
      end
    end
  end

  test "cannot report non existing quiz" do
    assert_no_difference "QuizReport.count" do
      assert_emails 0 do
        post api_quiz_report_path("non-existing"), params: { quiz_report: { spam: 1 } }, headers: api_sign_in(:confirmed)
        assert_response :not_found
      end
    end
  end

  test "cannot report quiz without verified email" do
    assert_no_difference "QuizReport.count" do
      assert_emails 0 do
        post api_quiz_report_path(quizzes(:two).uuid), params: { quiz_report: { spam: 1 } }, headers: api_sign_in(:one)
        assert_response :unauthorized
      end
    end
  end

  test "can update quiz" do
    patch api_quiz_update_path(quizzes(:one).uuid), params: { quiz: { title: "Updated Title" } }, headers: api_sign_in(:one)
    assert_response :success
    assert_equal "Updated Title", quizzes(:one).reload.title
  end

  test "cannot update quiz when not logged in" do
    patch api_quiz_update_path(quizzes(:one).uuid), params: { quiz: { title: "Updated Title" } }
    assert_response :unauthorized
  end

  test "cannot update non existing quiz" do
    patch api_quiz_update_path("non-existing"), params: { quiz: { title: "Updated Title" } }, headers: api_sign_in(:one)
    assert_response :not_found
  end

  test "cannot update quiz when not owner" do
    patch api_quiz_update_path(quizzes(:one).uuid), params: { quiz: { title: "Updated Title" } }, headers: api_sign_in(:two)
    assert_response :not_found
  end

  test "can favorite quiz" do
    assert_difference "FavoriteQuiz.count", 1 do
      patch api_quiz_favorite_path(quizzes(:one).uuid), params: { favorite: 1 }, headers: api_sign_in(:one)
    end
    assert_response :success
    assert users(:one).favorite_quiz?(quizzes(:one))
  end

  test "can unfavorite quiz" do
    assert_difference "FavoriteQuiz.count", -1 do
      patch api_quiz_favorite_path(quizzes(:two).uuid), headers: api_sign_in(:two)
    end
    assert_response :success
    assert_not users(:two).favorite_quiz?(quizzes(:two))
  end

  test "cannot favorite quiz when not logged in" do
    assert_no_difference "FavoriteQuiz.count" do
      patch api_quiz_favorite_path(quizzes(:one).uuid), params: { favorite: 1 }
    end
    assert_response :unauthorized
  end

  test "cannot favorite non existing quiz" do
    assert_no_difference "FavoriteQuiz.count" do
      patch api_quiz_favorite_path("non-existing"), params: { favorite: 1 }, headers: api_sign_in(:one)
    end
    assert_response :not_found
  end

  test "can delete quiz" do
    get api_quiz_request_delete_path(quizzes(:one).uuid), headers: api_sign_in(:one)
    assert_response :success

    token = @response.parsed_body["token"]

    assert_difference "Quiz.count", -1 do
      delete api_quiz_delete_path(quizzes(:one).uuid, token), headers: api_sign_in(:one)
    end
  end

  test "cannot get delete token when not logged in" do
    get api_quiz_request_delete_path(quizzes(:one).uuid)
    assert_response :unauthorized
  end

  test "cannot get delete token for quiz you don't own" do
    get api_quiz_request_delete_path(quizzes(:one).uuid), headers: api_sign_in(:two)
    assert_response :unauthorized
  end

  test "cannot delete quiz when not logged in" do
    get api_quiz_request_delete_path(quizzes(:one).uuid), headers: api_sign_in(:one)
    assert_response :success

    token = @response.parsed_body["token"]

    assert_no_difference "Quiz.count" do
      delete api_quiz_delete_path(quizzes(:one).uuid, token)
    end
    assert_response :unauthorized
  end

  test "cannot delete quiz you don't own" do
    get api_quiz_request_delete_path(quizzes(:one).uuid), headers: api_sign_in(:one)
    assert_response :success

    token = @response.parsed_body["token"]

    assert_no_difference "Quiz.count" do
      delete api_quiz_delete_path(quizzes(:one).uuid, token), headers: api_sign_in(:two)
    end
    assert_response :unauthorized
  end

  test "can favorite a score" do
    assert_changes -> { scores(:one).reload.favorite } do
      patch api_quiz_favorite_score_path(quizzes(:one).uuid, scores(:one).id), params: { favorite: true }, headers: api_sign_in(:one)
      assert_response :success
    end

    @response.parsed_body["updated_data"].each do |translation|
      next if translation["score_id"] != scores(:one).id

      assert translation["favorite"]
    end

    assert_changes -> { scores(:one).reload.favorite } do
      patch api_quiz_favorite_score_path(quizzes(:one).uuid, scores(:one).id), params: { favorite: false }, headers: api_sign_in(:one)
      assert_response :success
    end

    @response.parsed_body["updated_data"].each do |translation|
      assert_not translation["favorite"]
    end
  end

  test "cannot favorite a score when not logged in" do
    assert_no_changes -> { scores(:one).reload.favorite } do
      patch api_quiz_favorite_score_path(quizzes(:one).uuid, scores(:one).id), params: { favorite: true }
      assert_response :unauthorized
    end
  end

  test "cannot favorite a score on non existing quiz" do
    assert_no_changes -> { scores(:one).reload.favorite } do
      patch api_quiz_favorite_score_path("non-existing", scores(:one).id), params: { favorite: true }, headers: api_sign_in(:one)
      assert_response :not_found
    end
  end

  test "cannot favorite a score on non existing score" do
    assert_no_changes -> { scores(:one).reload.favorite } do
      patch api_quiz_favorite_score_path(quizzes(:one).uuid, "non-existing"), params: { favorite: true }, headers: api_sign_in(:one)
      assert_response :not_found
    end
  end

  test "cannot favorite score for wrong quiz" do
    assert_no_changes -> { scores(:one).reload.favorite } do
      patch api_quiz_favorite_score_path(quizzes(:two).uuid, scores(:one).id), params: { favorite: true }, headers: api_sign_in(:one)
      assert_response :bad_request
    end
  end

  test "change scores" do
    assert_changes -> { scores(:one).reload.cards }, from: 0, to: 5 do
      patch api_quiz_score_path(quizzes(:one).uuid, scores(:one).id, :cards), params: { score: 5 }, headers: api_sign_in(:one)
      assert_response :success
    end

    updated_data = @response.parsed_body["updated_data"]
    updated_data.each do |translation|
      translation["score"]["cards"] = 1
      translation["score"]["multi"] = 1
      translation["score"]["smart"] = 1
      translation["score"]["write"] = 1
      translation["updated"] = 5.seconds.from_now.to_i
      translation["score_id"] = translation["score_id"].to_i
    end
    data = {
      favorite: true,
      data: updated_data
    }

    assert_changes -> { users(:one).favorite_quiz?(quizzes(:one)) } do
      patch api_quiz_sync_score_path(quizzes(:one).uuid), params: { quiz: data }, headers: api_sign_in(:one), as: :json
    end

    @response.parsed_body["quiz_data"]["data"].each do |translation|
      assert_equal 1, translation["score"]["cards"]
      assert_equal 1, translation["score"]["multi"]
      assert_equal 1, translation["score"]["smart"]
      assert_equal 1, translation["score"]["write"]
    end

    patch api_quiz_reset_score_path(quizzes(:one).uuid, :cards), headers: api_sign_in(:one)
    assert_response :success

    @response.parsed_body["updated_data"].each do |translation|
      assert_equal 0, translation["score"]["cards"]
    end
  end
end
