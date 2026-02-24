require "test_helper"

class LanguageTest < ActiveSupport::TestCase
  test "should not save language without attributes" do
    language = Language.new
    assert_not language.save
  end

  test "should not save language without name" do
    language = Language.new(locale: "en")
    assert_not language.save
  end

  test "should not save language wihout locale" do
    language = Language.new(name: "English")
    assert_not language.save
  end

  test "should not save duplicate language" do
    language = Language.new(name: "English", locale: "en")
    assert_not language.save
  end
end
