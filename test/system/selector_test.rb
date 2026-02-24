require "application_system_test_case"

class SelectorTest < ApplicationSystemTestCase
  test "selector" do
    visit root_url
    assert find_test_id "root-welcome"
  end
end
