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

    @account.enable_prior_sync!(
      account_number: prior_account_params[:account_number].presence,
      name: prior_account_params[:name].presence || @account.name
    )

    redirect_to account_path(@account), notice: "Priorbank account linked successfully"
  rescue ActiveRecord::RecordInvalid => e
    @prior_account = PriorAccount.new(prior_account_params)
    @error_message = e.message
    render :new, status: :unprocessable_entity
  end

  def edit_sync
    unless @account.prior_enabled?
      redirect_to account_path(@account), alert: "Priorbank is not enabled for this account"
    end
  end

  def sync
    unless @account.prior_enabled?
      redirect_to account_path(@account), alert: "Priorbank is not enabled for this account"
      return
    end

    window_start_date = sync_params[:start_date].present? ? Date.parse(sync_params[:start_date]) : nil
    window_end_date = sync_params[:end_date].present? ? Date.parse(sync_params[:end_date]) : nil

    if window_start_date && window_end_date
      date_range_in_months = ((window_end_date.year * 12 + window_end_date.month) - (window_start_date.year * 12 + window_start_date.month))

      if date_range_in_months > 3
        redirect_to account_path(@account), alert: "Date range cannot exceed 3 months. Please select a shorter period."
        return
      end
    end

    @account.prior_account.sync_later(
      window_start_date: window_start_date,
      window_end_date: window_end_date
    )

    redirect_to account_path(@account), notice: "Syncing Priorbank transactions..."
  end

  def destroy
    @account.disable_prior_sync!
    redirect_to account_path(@account), notice: "Priorbank account unlinked"
  end

  private

    def set_account
      @account = Current.family.accounts.find(params[:account_id])
    end

    def prior_account_params
      params.require(:prior_account).permit(:account_number, :name)
    end

    def sync_params
      params.permit(:start_date, :end_date)
    end
end
