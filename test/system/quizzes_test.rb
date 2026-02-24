require "application_system_test_case"

class QuizzesTest < ApplicationSystemTestCase
  test "creating a quiz" do
    add_user_to_db
    login
    close_notice

    assert find_test_id("navbar-account").click
    assert find_test_id("navbar-create-quiz").click
    assert_current_path quiz_create_path

    find_test_id("quiz-create").click

    assert_text t "activerecord.errors.models.quiz.attributes.title.too_short"

    close_notice

    title = "HELLO"
    description = "This is a cool quiz"

    find_test_id("quiz-title").fill_in with: title
    find_test_id("quiz-description").fill_in with: description

    lang_from = Language.all[Random.rand 0..Language.count - 1]
    lang_to = Language.all[Random.rand 0..Language.count - 1]

    find_test_id("from-lang").find(
      :option,
      text: t("general.languages.#{lang_from.locale}")
    ).select_option
    find_test_id("to-lang").find(
      :option,
      text: t("general.languages.#{lang_to.locale}")
    ).select_option

    translation_data = [%w[Baum Tree], %w[Hallo Hello], %w[Testing Testing]]

    translation_data.each_with_index do |data, i|
      find_field("quiz[translations_attributes][#{i}][word]").fill_in with: data[0]
      find_field("quiz[translations_attributes][#{i}][translation]").fill_in with: data[1]
    end

    find_test_id("quiz-create").click

    assert_text t "quiz.quiz.new.quiz_created"
    assert_current_path quiz_show_path Quiz.last.uuid
    close_notice

    translation_data.each do |data|
      assert_text data[0]
      assert_text data[1]
    end

    assert_text title
    assert_text description
  end
end
