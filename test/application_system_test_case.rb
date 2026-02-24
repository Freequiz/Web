require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  def setup
    Capybara.server_host = "0.0.0.0" # bind to all interfaces
    Capybara.app_host = "http://#{IPSocket.getaddress(Socket.gethostname)}" if ENV["SELENIUM_REMOTE_URL"].present?
    super
  end

  url = ENV.fetch("SELENIUM_REMOTE_URL", nil)
  options = if url
              { browser: :remote, url: url }
            else
              { browser: :chrome }
            end
  chrome = if url
             :chrome
           else
             :headless_chrome
           end
  driven_by :selenium, using: chrome, options: options

  def find_test_id(test_id)
    find(:test_id, test_id)
  end

  def create_user_with(
    visit: true,
    username: "Testing",
    email: "test@freequiz.ch",
    password: "hallO123",
    password_confirmation: "hallO123",
    agb: true
  )
    visit user_create_url if visit

    fill_in I18n.t("user.user.new.username"), with: username
    fill_in I18n.t("user.user.new.email"), with: email
    fill_in I18n.t("user.user.new.password"), with: password
    fill_in I18n.t("user.user.new.repeat_password"), with: password_confirmation
    check I18n.t("user.user.new.accept_agb", link: I18n.t("user.user.new.agb")) if agb
    click_on I18n.t "user.user.new.submit_create_account"
  end
  alias create_user create_user_with

  def add_user_to_db
    User.create username: "Testing",
                password: "hallO123",
                email: "test@freequiz.ch",
                agb: true,
                role: "user"
  end

  def t(key)
    I18n.t key
  end

  def login(password: "hallO123")
    visit user_login_url
    assert_text I18n.t "user.sessions.new.login_page"

    fill_in I18n.t("general.email_or_username"), with: "Testing"
    fill_in I18n.t("general.password"), with: password
    find("#login").click
  end

  def close_notice
    find("#close-notice").click
  end
end
