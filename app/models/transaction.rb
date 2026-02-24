class Transaction < ApplicationRecord
  belongs_to :user, optional: true

  validates :amount, presence: true
  validates :description, presence: true

  def self.total
    total = 0
    Transaction.where(removed: false).each do |transaction|
      total += transaction.amount
    end
    total.round(2)
  end

  def color
    Transaction.number_color amount
  end

  def self.color
    Transaction.number_color Transaction.total
  end

  def self.number_color(num)
    if num.positive?
      "text-green-600"
    elsif num.negative?
      "text-red-600"
    else
      "text-black"
    end
  end
end
