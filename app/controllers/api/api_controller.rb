class Api::ApiController < ApplicationController
  include ApiUtils

  protect_from_forgery with: :null_session
  around_action :locale_en
  skip_before_action :setup_login
  skip_around_action :switch_locale

  def languages
    language_data = {}
    Language.all.each do |lang|
      language_data[lang.id] = { name: lang.name, locale: lang.locale }
    end
    json({ success: true, data: language_data })
  end
end
