require "test_helper"

class Api::ApiControllerTest < ActionDispatch::IntegrationTest
  test "should get languages" do
    get api_languages_url

    json = @response.parsed_body

    assert_response :success
    assert_equal true, json["success"]
    assert_not_nil json["data"]
    assert_equal Language.count, json["data"].length
  end
end
