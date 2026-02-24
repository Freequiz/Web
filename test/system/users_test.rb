require "application_system_test_case"

class UsersTest < ApplicationSystemTestCase
  test "creating account" do
    visit root_url
    assert_text I18n.t "home.root.welcome"

    click_on I18n.t("general.create_account"), match: :first
    assert_current_path user_create_path

    create_user_with visit: false

    assert_text I18n.t("user.user.new.created").sub("%s", "Testing")
    assert User.find_by(username: "Testing").present?
  end

  test "no account with same username or email" do
    create_user
    close_notice
    visit user_logout_path
    close_notice
    create_user
    assert_current_path user_create_path
    assert_text I18n.t "activerecord.errors.models.user.attributes.username.taken"
    assert_text I18n.t "activerecord.errors.models.user.attributes.email.taken"
  end

  test "login" do
    add_user_to_db
    login

    assert_text I18n.t("user.sessions.new.success").sub("%s", "Testing")

    visit user_url
    assert_text I18n.t("user.user.show.title")

    visit user_login_url
    assert_text I18n.t("user.sessions.new.already_logged_in")

    visit user_logout_url
    assert_text I18n.t("user.sessions.destroy.success")

    visit user_url
    assert_text I18n.t("general.login_required")
  end

  test "editing account" do
    add_user_to_db
    login

    click_on I18n.t "user.user.show.buttons.edit"
    assert_text I18n.t("user.user.edit.title")

    fill_in I18n.t("general.username"), with: "Edited"
    click_on I18n.t "general.save"
    assert_text I18n.t "user.user.show.title"
    assert_equal "Edited", User.find_by(email: "test@freequiz.ch").username

    click_on I18n.t "user.user.show.buttons.edit"
    fill_in I18n.t("general.password"), with: "HelloWorld42"
    fill_in I18n.t("user.user.edit.password_repeat"), with: "HelloWorld41"
    fill_in I18n.t("user.user.edit.old_password"), with: "hallo123"
    click_on I18n.t "general.save"
    assert_text I18n.t("activerecord.errors.models.user.attributes.password_challenge.invalid")

    fill_in I18n.t("general.password"), with: "HelloWorld42"
    fill_in I18n.t("user.user.edit.password_repeat"), with: "HelloWorld41"
    fill_in I18n.t("user.user.edit.old_password"), with: "hallO123"
    click_on I18n.t "general.save"
    assert_text I18n.t(
      "activerecord.errors.models.user.attributes.password.confirmation"
    )

    fill_in I18n.t("general.username"), with: "Testing"
    fill_in I18n.t("general.password"), with: "HelloWorld42"
    fill_in I18n.t("user.user.edit.password_repeat"), with: "HelloWorld42"
    fill_in I18n.t("user.user.edit.old_password"), with: "hallO123"
    click_on I18n.t "general.save"
    assert_text I18n.t("user.user.edit.saved_data")
    assert User.find_by(username: "Testing").present?

    visit user_logout_url
    login
    assert_text I18n.t("user.sessions.new.wrong_password")

    login password: "HelloWorld42"
    assert_text I18n.t("user.sessions.new.success").sub("%s", "Testing")
  end

  test "deleting account" do
    add_user_to_db
    login

    click_on t "user.user.show.buttons.delete"
    assert_text t "user.user.request_destroy.delete_account"
    accept_confirm do
      click_on t "user.user.request_destroy.delete"
    end
    assert_text t "user.user.destroy.deleted"
  end
end
