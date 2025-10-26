class Accounts::PriorAccountsController < ApplicationController
  before_action :set_account

  def new
    @prior_account = PriorAccount.new
  end

  def create
    if @account.linked?
      redirect_to account_path(@account), alert: "Cannot link Priorbank to a linked account"
      return
    end

    @account.enable_priorbank_sync!(
      account_number: prior_account_params[:account_number].presence,
      name: prior_account_params[:name].presence || @account.name
    )

    redirect_to account_path(@account), notice: "Priorbank account linked successfully"
  rescue ActiveRecord::RecordInvalid => e
    @prior_account = PriorAccount.new(prior_account_params)
    @error_message = e.message
    render :new, status: :unprocessable_entity
  end

  def destroy
    @account.disable_priorbank_sync!
    redirect_to account_path(@account), notice: "Priorbank account unlinked"
  end

  private

    def set_account
      @account = Current.family.accounts.find(params[:account_id])
    end

    def prior_account_params
      params.require(:prior_account).permit(:account_number, :name)
    end
end
