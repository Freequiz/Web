class QuizReport < ApplicationRecord
  belongs_to :quiz, optional: true
  belongs_to :user, optional: true

  validates :status, inclusion: { in: %w[open solved ignored deleted] }

  KEYS = %i[sexual violence hate spam child_abuse mobbing].freeze
end
