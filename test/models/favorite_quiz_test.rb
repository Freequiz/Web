require "test_helper"

class FavoriteQuizTest < ActiveSupport::TestCase
  test "can favorite a quiz" do
    user = users(:one)
    quiz = quizzes(:one)

    assert_difference -> { user.favorite_quizzes.count }, 1 do
      FavoriteQuiz.create(user: user, quiz: quiz)
    end

    assert user.favorite_quiz?(quiz)
  end

  test "can unfavorite a quiz" do
    user = users(:two)
    quiz = quizzes(:two)

    assert_difference -> { user.favorite_quizzes.count }, -1 do
      FavoriteQuiz.find_by(user: user, quiz: quiz).destroy
    end

    assert_not user.favorite_quiz?(quiz)
  end

  test "cannot create a duplicate favorite" do
    user = users(:one)
    quiz = quizzes(:one)

    assert_difference -> { user.favorite_quizzes.count }, 1 do
      FavoriteQuiz.create(user: user, quiz: quiz)
      second = FavoriteQuiz.new(user: user, quiz: quiz)
      assert_not second.save
    end

    assert user.favorite_quiz?(quiz)
  end

  test "needs both user and quiz" do
    assert_no_difference "FavoriteQuiz.count" do
      FavoriteQuiz.create
    end
  end

  test "needs a user" do
    quiz = quizzes(:one)

    assert_no_difference "FavoriteQuiz.count" do
      FavoriteQuiz.create(quiz: quiz)
    end
  end

  test "needs a quiz" do
    user = users(:one)

    assert_no_difference "FavoriteQuiz.count" do
      FavoriteQuiz.create(user: user)
    end
  end
end
