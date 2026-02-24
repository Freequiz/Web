require "test_helper"

class Admin::TransactionControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    sign_in :admin

    get admin_new_transaction_path
    assert_response :success
  end

  test "cannot get new if not admin" do
    sign_in :one

    get admin_new_transaction_path
    assert_response :not_found
  end

  test "cannot get new if not logged in" do
    get admin_new_transaction_path
    assert_response :not_found
  end

  test "should create transaction" do
    sign_in :admin

    assert_difference "Transaction.total", 100 do
      post admin_new_transaction_path, params: { transaction: { amount: 100, description: "test" } }
      assert_redirected_to admin_transactions_url
    end
  end

  test "cannot create transaction if not admin" do
    sign_in :one

    assert_no_difference "Transaction.total" do
      post admin_new_transaction_path, params: { transaction: { amount: 100, description: "test" } }
      assert_response :not_found
    end
  end

  test "cannot create transaction if not logged in" do
    assert_no_difference "Transaction.total" do
      post admin_new_transaction_path, params: { transaction: { amount: 100, description: "test" } }
      assert_response :not_found
    end
  end

  test "should get list" do
    sign_in :admin

    get admin_transactions_path
    assert_response :success
  end

  test "cannot get list if not admin" do
    sign_in :one

    get admin_transactions_path
    assert_response :not_found
  end

  test "cannot get list if not logged in" do
    get admin_transactions_path
    assert_response :not_found
  end

  test "should get show" do
    sign_in :admin

    get admin_show_transaction_path(transaction_id: transactions(:one).id)
    assert_response :success
  end

  test "cannot get show if not admin" do
    sign_in :one

    get admin_show_transaction_path(transaction_id: transactions(:one).id)
    assert_response :not_found
  end

  test "cannot get show if not logged in" do
    get admin_show_transaction_path(transaction_id: transactions(:one).id)
    assert_response :not_found
  end

  test "should get removed" do
    sign_in :admin

    get admin_removed_transactions_path
    assert_response :success
  end

  test "cannot get removed if not admin" do
    sign_in :one

    get admin_removed_transactions_path
    assert_response :not_found
  end

  test "cannot get removed if not logged in" do
    get admin_removed_transactions_path
    assert_response :not_found
  end

  test "should delete transaction" do
    sign_in :admin

    assert_difference "Transaction.total", -1 do
      delete admin_delete_transaction_path(transaction_id: transactions(:one).id)
      assert_redirected_to admin_transactions_path
    end
  end

  test "cannot delete transaction if not admin" do
    sign_in :one

    assert_no_difference "Transaction.total" do
      delete admin_delete_transaction_path(transaction_id: transactions(:one).id)
      assert_response :not_found
    end
  end

  test "cannot delete transaction if not logged in" do
    assert_no_difference "Transaction.total" do
      delete admin_delete_transaction_path(transaction_id: transactions(:one).id)
      assert_response :not_found
    end
  end

  test "should restore transaction" do
    sign_in :admin

    assert_difference "Transaction.total", 2 do
      patch admin_restore_transaction_path(transaction_id: transactions(:three).id)
      assert_redirected_to admin_transactions_path
      assert_not transactions(:three).reload.removed
    end
  end

  test "cannot restore transaction if not admin" do
    sign_in :one

    assert_no_difference "Transaction.total" do
      patch admin_restore_transaction_path(transaction_id: transactions(:three).id)
      assert_response :not_found
    end
  end

  test "cannot restore transaction if not logged in" do
    assert_no_difference "Transaction.total" do
      patch admin_restore_transaction_path(transaction_id: transactions(:three).id)
      assert_response :not_found
    end
  end
end
