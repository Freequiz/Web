require "application_system_test_case"

class ImportQuizzesTest < ApplicationSystemTestCase
  test "importing a quiz" do
    add_user_to_db
    login
    assert_text I18n.t("user.sessions.new.success") % "Testing"

    visit quiz_create_path
    fill_in "Title", with: "Test Quiz"

    click_on I18n.t("quiz.quiz.new.import_text")

    text = file_fixture("quiz_text.txt").read
    num_translations = text.split("\n").length

    textarea = find(:xpath, "//textarea[@data-create-quiz-target='importTextField']")
    textarea.fill_in(with: text)

    accept_confirm do
      click_on I18n.t("quiz.quiz.new.load")
    end

    assert_difference "Quiz.count", 1 do
      click_on I18n.t("quiz.quiz.new.create_quiz")
      assert_text I18n.t("quiz.quiz.show.cards")
      assert_text "Test Quiz"
    end

    assert_equal num_translations, Quiz.last.translations.count
  end
end
