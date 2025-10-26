module Account::PriorbankSyncable
  extend ActiveSupport::Concern

  def priorbank_enabled?
    prior_account.present?
  end

  def enable_priorbank_sync!(account_number: nil, name: nil)
    return if prior_account.present?

    prior = PriorAccount.create!(
      account_number: account_number,
      name: name || self.name,
      currency: currency
    )

    update!(prior_account: prior)
  end

  def disable_priorbank_sync!
    return unless prior_account.present?

    prior_account.destroy
  end

end
