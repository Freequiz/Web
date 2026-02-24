require "test_helper"

class BlockedUserDatumTest < ActiveSupport::TestCase
  test "freequiz is blocked" do
    assert BlockedUserDatum.username_blocked?("freequiz")
  end

  test "freequiz is blocked with extra characters" do
    assert BlockedUserDatum.username_blocked?("Freequiz123")
  end

  test "admin is blocked" do
    assert BlockedUserDatum.username_blocked?("admin")
  end

  test "other usernames are not blocked" do
    usernames = %w[
      Mark
      John
      Luke
      Matthew
      Shadow123
      Shadow
      Shadow_123
      xXShadowXx
      ShadowX
      annyoance
      abcdefghijklmnopqrstuvwxyz
      thequickbrownfoxjumpsoverthelazydog123
      packmyboxwithfivedozenliquorjugs
      howquicklydaftjumpingzebrasvex
      sphinxofblackquartzjudgemyvow
      abcdefghijklmnopqrstuvwxyz98765
    ]

    usernames.each { |username| assert_not BlockedUserDatum.username_blocked?(username) }
  end
end
