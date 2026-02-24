class Score < ApplicationRecord
  belongs_to :user
  belongs_to :translation

  MODES = %i[cards write multi smart].freeze

  validates :user_id, uniqueness: { scope: :translation_id }
  validates :favorite, inclusion: { in: [true, false] }
end
