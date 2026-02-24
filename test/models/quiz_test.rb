require "test_helper"

class QuizTest < ActiveSupport::TestCase
  test "can create quiz" do
    assert Quiz.new(
      title: "Quiz",
      description: "Description",
      from: language_id("german"),
      to: language_id("french"),
      visibility: "public",
      translations_attributes: [
        { word: "Baum", translation: "Arbre" }
      ]
    ).save
  end

  test "cannot create quiz without translations" do
    assert_not Quiz.new(
      title: "Quiz",
      description: "Description",
      from: language_id("german"),
      to: language_id("french"),
      visibility: "public"
    ).save
  end

  test "cannot create quiz without title" do
    assert_not Quiz.new(
      description: "Description",
      from: language_id("german"),
      to: language_id("french"),
      visibility: "public",
      translations_attributes: [
        { word: "Baum", translation: "Arbre" }
      ]
    ).save
  end

  test "can create quiz without description" do
    assert Quiz.new(
      title: "Quiz",
      from: language_id("german"),
      to: language_id("french"),
      visibility: "public",
      translations_attributes: [
        { word: "Baum", translation: "Arbre" }
      ]
    ).save
  end

  test "cannot create quiz without from language" do
    assert_not Quiz.new(
      title: "Quiz",
      description: "Description",
      to: language_id("french"),
      visibility: "public",
      translations_attributes: [
        { word: "Baum", translation: "Arbre" }
      ]
    ).save
  end

  test "cannot create quiz without to language" do
    assert_not Quiz.new(
      title: "Quiz",
      description: "Description",
      from: language_id("german"),
      visibility: "public",
      translations_attributes: [
        { word: "Baum", translation: "Arbre" }
      ]
    ).save
  end

  test "cannot create quiz without visibility" do
    assert_not Quiz.new(
      title: "Quiz",
      description: "Description",
      from: language_id("german"),
      to: language_id("french"),
      translations_attributes: [
        { word: "Baum", translation: "Arbre" }
      ]
    ).save
  end

  test "cannot create quiz with invalid visibility" do
    assert_not Quiz.new(
      title: "Quiz",
      description: "Description",
      from: language_id("german"),
      to: language_id("french"),
      visibility: "invalid",
      translations_attributes: [
        { word: "Baum", translation: "Arbre" }
      ]
    ).save
  end

  test "can create quiz with multiple translations" do
    quiz = Quiz.new(
      title: "Quiz",
      description: "Description",
      from: language_id("german"),
      to: language_id("french"),
      visibility: "public",
      translations_attributes: [
        { word: "Baum", translation: "Arbre" },
        { word: "Haus", translation: "Maison" }
      ]
    )
    assert quiz.save
    assert_equal 2, quiz.translations.count
  end

  test "can create quiz with multiple translations with same word" do
    quiz = Quiz.new(
      title: "Quiz",
      description: "Description",
      from: language_id("german"),
      to: language_id("french"),
      visibility: "public",
      translations_attributes: [
        { word: "Baum", translation: "Arbre" },
        { word: "Baum", translation: "Arbre" }
      ]
    )
    assert quiz.save
    assert_equal 2, quiz.translations.count
  end

  test "invalid translations get filtered out" do
    quiz = Quiz.new(
      title: "Quiz",
      description: "Description",
      from: language_id("german"),
      to: language_id("french"),
      visibility: "public",
      translations_attributes: [
        { word: "Baum", translation: "Arbre" },
        { word: "Baum", translation: "" }
      ]
    )
    assert quiz.save
    assert_equal 1, quiz.translations.count
  end

  test "can update quiz" do
    quiz = quizzes(:one)
    quiz.title = "New title"
    assert quiz.save
  end

  test "cannot update quiz without title" do
    quiz = quizzes(:one)
    quiz.title = ""
    assert_not quiz.save
  end

  test "can update all the quiz data" do
    quiz = quizzes(:one)
    quiz.title = "New title"
    quiz.description = "New description"
    quiz.from = language_id("chinese")
    quiz.to = language_id("italian")
    quiz.visibility = "private"
    quiz.translations.each do |translation|
      translation.word = "New word"
      translation.translation = "New translation"
    end
    assert_equal 2, quiz.translations.select { |t| t.word == "New word" }.count
    assert_equal Language.find_by(name: "chinese"), quiz.from_lang
    assert_equal Language.find_by(name: "italian"), quiz.to_lang
    assert quiz.user_allowed_to_view?(users(:one))
    assert_not quiz.user_allowed_to_view?(users(:two))
    assert quiz.save
  end

  test "can delete quiz" do
    quiz_id = quizzes(:one).id
    translations_ids = quizzes(:one).translations.pluck(:id)
    assert quizzes(:one).destroy
    assert_not Quiz.exists?(quiz_id)
    translations_ids.each { |id| assert_not Translation.exists?(id) }
  end

  test "private quiz is not visible to other users" do
    quiz = quizzes(:private)
    assert_not quiz.user_allowed_to_view?(users(:two))
  end

  test "hidden quiz is viewable by other users" do
    quiz = quizzes(:hidden)
    assert quiz.user_allowed_to_view?(users(:two))
  end

  test "public quiz is viewable by other users" do
    quiz = quizzes(:one)
    assert quiz.user_allowed_to_view?(users(:two))
  end

  test "private quiz does not show up in search results" do
    Quiz.search_all_quizzes({}).first.each do |quiz|
      assert_not_equal "private", quiz.visibility
    end
  end

  test "search results have one page" do
    assert_equal 1, Quiz.search_all_quizzes({}).last
  end

  test "search results have multiple pages" do
    quiz_count = Quiz.where(visibility: "public").count
    10.times do |pages|
      50.times do
        Quiz.create(
          title: "Quiz",
          description: "Description",
          from: language_id("german"),
          to: language_id("french"),
          visibility: "public",
          translations_attributes: [
            { word: "Baum", translation: "Arbre" }
          ]
        )
      end
      assert_equal pages + 2, Quiz.search_all_quizzes({}).last
      assert_equal quiz_count, Quiz.search_all_quizzes({ page: pages + 2 }).first.count
    end
  end

  test "search results have correct quizzes" do
    quiz = quizzes(:one)
    search_results = Quiz.search_all_quizzes({ title: quiz.title })
    assert_equal search_results.first.first, quiz
  end

  test "user quiz search contain hidden and private quizzes" do
    user = users(:one)
    assert_equal user.quizzes.count, Quiz.search_user_quizzes(user, {}).first.count
  end

  test "cannot inject SQL in search query" do
    search_results = Quiz.search_all_quizzes({ title: "'; DROP TABLE quizzes; --" })
    assert search_results.first.count.positive?
    assert ActiveRecord::Base.connection.table_exists?("quizzes")
  end

  test "score creation and sync" do
    quiz = quizzes(:one)
    user = users(:one)

    learn_data = quiz.learn_data(user)

    quiz.translations.each do |translation|
      assert user.scores.exists?(translation_id: translation.id)
    end

    learn_data.each do |score_data|
      assert_equal false, score_data[:favorite]
      assert_equal({ smart: 0, write: 0, multi: 0, cards: 0 }, score_data[:score].transform_keys(&:to_sym))
    end

    assert_not user.favorite_quiz?(quiz)

    quiz.sync_score(
      {
        favorite: true,
        data: learn_data
      },
      user
    )

    assert user.favorite_quiz?(quiz)

    learn_data[0][:favorite] = true
    learn_data[0][:score][:smart] = 1
    learn_data[0][:score][:write] = 2
    learn_data[0][:score][:multi] = 3
    learn_data[0][:score][:cards] = 4
    learn_data[0][:updated] = 30.seconds.from_now.to_i

    learn_data[1][:favorite] = true
    learn_data[1][:score][:smart] = 5
    learn_data[1][:score][:write] = 6
    learn_data[1][:score][:multi] = 7
    learn_data[1][:score][:cards] = 8

    quiz.sync_score(
      {
        favorite: true,
        data: learn_data
      },
      user
    )

    new_learn_data = quiz.learn_data(user)

    assert new_learn_data[0][:favorite]
    assert_equal 1, new_learn_data[0][:score]["smart"]
    assert_equal 2, new_learn_data[0][:score]["write"]
    assert_equal 3, new_learn_data[0][:score]["multi"]
    assert_equal 4, new_learn_data[0][:score]["cards"]

    assert_not new_learn_data[1][:favorite]
    assert_not_equal 5, new_learn_data[1][:score]["smart"]
    assert_not_equal 6, new_learn_data[1][:score]["write"]
    assert_not_equal 7, new_learn_data[1][:score]["multi"]
    assert_not_equal 8, new_learn_data[1][:score]["cards"]

    assert user.favorite_quiz?(quiz)
  end
end
