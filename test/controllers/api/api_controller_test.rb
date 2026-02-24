require "test_helper"

class Api::ApiControllerTest < ActionDispatch::IntegrationTest
  test "should get languages" do
    get api_languages_url

    json = @response.parsed_body

    assert_response :success
    assert_equal true, json["success"]
    assert_not_nil json["data"]
    assert_equal Language.count, json["data"].length

    Language.all.each do |lang|
      assert_equal lang.name, json["data"][lang.id.to_s]["name"]
      assert_equal lang.locale, json["data"][lang.id.to_s]["locale"]
    end
  end
end
