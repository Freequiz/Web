require "test_helper"

class TransactionTest < ActiveSupport::TestCase
  test "removed default" do
    transaction = Transaction.create amount: 1, description: "Rails Test"
    assert_equal 1, transaction.amount
    assert_equal "Rails Test", transaction.description
  end

  test "total value" do
    Transaction.destroy_all
    values = [10, 200, -20, -15.3, 23.4, -300, 111.1]
    values.each do |value|
      Transaction.create amount: value, description: "Test one two three"
    end
    assert_equal values.sum.round(2), Transaction.total
  end
end
