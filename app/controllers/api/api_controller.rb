class Api::ApiController < ApplicationController
  include ApiUtils

  protect_from_forgery with: :null_session
  around_action :locale_en
  skip_before_action :setup_login
  skip_around_action :switch_locale

  def languages
    @languages = Language.all
  end
end
