require "capybara"

Capybara.add_selector :test_id do
  css { |id| "[data-test-id='#{id}']" }
end
