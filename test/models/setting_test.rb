require "test_helper"

class SettingTest < ActiveSupport::TestCase
  test "should not save blank" do
    setting = Setting.new
    assert_not setting.save
  end

  test "locale is en by default" do
    setting = Setting.new
    assert_equal "en", setting.locale
  end

  test "has correct default values" do
    setting = Setting.new
    assert_equal true, setting.dark_mode
    assert_equal 2, setting.write_amount
    assert_equal 2, setting.cards_amount
    assert_equal 2, setting.multi_amount
    assert_equal 10, setting.round_amount
  end

  test "amounts are integers" do
    setting = Setting.new
    setting.write_amount = 1.5
    setting.cards_amount = 1.5
    setting.multi_amount = 1.5
    assert_not setting.save
  end

  test "amounts are between 1 and 3" do
    setting = Setting.new
    setting.write_amount = 0
    setting.cards_amount = 4
    setting.multi_amount = 5
    assert_not setting.save
  end

  test "round amount is an integer" do
    setting = Setting.new
    setting.round_amount = 1.5
    assert_not setting.save
  end

  test "round amount is in the correct range" do
    setting = Setting.new
    setting.round_amount = 4
    assert_not setting.save
  end
end
