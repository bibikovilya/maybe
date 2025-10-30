class SyncsController < ApplicationController
  layout "settings"

  before_action :set_sync, only: %i[show]

  def index
    prior_account_ids = Current.family.accounts.joins(:prior_account).pluck("prior_accounts.id")
    @syncs = Sync
      .where(syncable_type: "PriorAccount", syncable_id: prior_account_ids)
      .includes(:syncable)
      .ordered
  end

  def show
  end

  private
    def set_sync
      prior_account_ids = Current.family.accounts.joins(:prior_account).pluck("prior_accounts.id")
      @sync = Sync.where(syncable_type: "PriorAccount", syncable_id: prior_account_ids).find(params[:id])
    end
end
