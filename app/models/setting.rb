class Setting < ApplicationRecord
  belongs_to :user

  SETTING_KEYS = %i[dark_mode write_amount cards_amount multi_amount round_amount].freeze
  LOCALES = %w[de fr it en].freeze
  ROUND_AMOUNTS = [5, 10, 20, 30].freeze

  validates :locale, inclusion: { in: LOCALES }
  validates :write_amount, numericality: { only_integer: true, in: 1..3 }
  validates :cards_amount, numericality: { only_integer: true, in: 1..3 }
  validates :multi_amount, numericality: { only_integer: true, in: 1..3 }
  validates :round_amount, inclusion: { in: ROUND_AMOUNTS }

  def get_errors
    errors.objects.map(&:full_message)
  end
end
