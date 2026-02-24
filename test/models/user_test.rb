require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "do not create user without data" do
    user = User.new
    assert_not user.save
  end

  test "user accept agb" do
    user = User.new user_params_with(agb: "0")
    assert_not user.save
  end

  test "user password match" do
    user = User.new user_params_with(password_confirmation: "HallOO123")
    assert_not user.save
  end

  test "create user" do
    user = User.new user_params
    assert user.save
    assert user.setting
  end

  test "do not create users with the same username" do
    User.create user_params
    user = User.new user_params_with(email: "abc@freequiz.ch")

    assert_not user.save
  end

  test "do not create users with the same email" do
    User.create user_params
    user = User.new user_params_with(username: "hello")
    assert_not user.save
  end

  test "email downcase" do
    user = User.create(user_params_with(email: "aBc@FreeQuiz.CH"))
    assert_equal "abc@freequiz.ch", user.email
  end

  test "role on creation" do
    user = User.create(user_params)
    assert_equal "user", user.role
  end

  test "sign in count" do
    user = User.create(user_params)
    assert_equal user.sign_in_count, 1
  end

  test "can destroy user" do
    user = users(:one)
    assert user.destroy
    assert_not Setting.find_by(user_id: user.id)
  end

  test "can destroy user with scores" do
    user = users(:one)
    user.scores.create(translation: translations(:one))
    assert user.destroy
    assert_not Score.find_by(user_id: user.id)
  end

  test "can destroy user with transactions" do
    user = users(:one)
    user.transactions.create(amount: 10)
    transaction_ids = users(:one).transactions.pluck(:id)
    assert user.destroy
    transaction_ids.each { |id| assert Transaction.exists?(id) }
  end
end
