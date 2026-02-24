class Admin::TransactionController < ApplicationController
  before_action :require_admin!

  def new
    @transaction = Transaction.new
  end

  def create
    @transaction = current_user.transactions.new(transaction_params)
    if @transaction.save
      redirect_to admin_transactions_path, notice: "Transaction created"
    else
      flash.now.alert = "Transaction could not be saved"
      render :new, status: :unprocessable_entity
    end
  end

  def list
    @total = Transaction.total
    @transactions = Transaction.where(removed: false).order(created_at: :desc)
  end

  def show
    @transaction = Transaction.find_by(id: params[:transaction_id])

    return if @transaction.present?

    redirect_to admin_transactions_path, notice: "Transaction doesn't exist"
  end

  def removed
    @transactions = Transaction.where(removed: true).order(created_at: :desc)
  end

  def delete
    update_transaction_removed true
  end

  def restore
    update_transaction_removed false
  end

  private

  def transaction_params
    params.require(:transaction).permit(:amount, :description)
  end

  def update_transaction_removed(value)
    transaction = Transaction.find_by(id: params[:transaction_id])

    redirect_to admin_transactions_path, notice: "Transaction doesn't exist" unless transaction.present?

    transaction.update(removed: value)
    redirect_to admin_transactions_path, notice: "Transaction #{value ? "removed" : "restored"}"
  end
end
