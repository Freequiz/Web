class BannedIp < ApplicationRecord
  def self.ip_banned?(ip)
    BannedIp.exists?(ip:)
  end

  def self.get_reason(ip)
    BannedIp.find_by(ip:)&.reason
  end
end
