class Translation < ApplicationRecord
  belongs_to :quiz, counter_cache: true
  has_many :scores, dependent: :destroy
end
