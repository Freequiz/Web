class BlockedUserDatum < ApplicationRecord
  def self.username_blocked?(username)
    BlockedUserDatum.exists?(username: username&.downcase) || BlockedUserDatum.where("? LIKE '%' || username || '%'", username&.downcase).first.present?
  end
end
