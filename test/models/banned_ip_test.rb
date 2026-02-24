require "test_helper"

class BannedIpTest < ActiveSupport::TestCase
  test "can create a banned ip" do
    banned_ip = BannedIp.new(ip: "0.0.0.0", reason: "Test")
    assert banned_ip.save
  end

  test "can destroy a banned ip" do
    banned_ip = banned_ips(:one)
    assert banned_ip.destroy
  end
end
