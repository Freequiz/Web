require "test_helper"

class TranslationTest < ActiveSupport::TestCase
  test "should not save translation without quiz" do
    translation = Translation.new(word: "Hello", translation: "Hallo")
    assert_not translation.save
  end

  test "should save translation with quiz" do
    quiz = quizzes(:one)
    translation = Translation.new(word: "Hello", translation: "Hallo", quiz: quiz)
    assert translation.save
  end

  test "can destroy translation" do
    translation = translations(:one)
    assert translation.destroy
    assert_not Score.find_by(translation_id: translation.id)
  end
end
