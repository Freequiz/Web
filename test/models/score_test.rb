require "test_helper"

class ScoreTest < ActiveSupport::TestCase
  test "should not save score without user_id" do
    score = Score.new(translation: translations(:one))
    assert_not score.save
  end

  test "should not save score without translation_id" do
    score = Score.new(user: users(:one))
    assert_not score.save
  end

  test "should save score with user_id and translation_id" do
    score = Score.new(user: users(:one), translation: translations(:two))
    assert score.save
  end

  test "should not save score with duplicate user_id and translation_id" do
    score = Score.new(user: users(:one), translation: translations(:one))
    assert_not score.save
  end
end
