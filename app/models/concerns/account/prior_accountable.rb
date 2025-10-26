module Account::PriorAccountable
  extend ActiveSupport::Concern

  included do
    belongs_to :prior_account, optional: true
  end

  def prior_enabled?
    prior_account.present?
  end

  def enable_prior_sync!(account_number: nil, name: nil)
    return if prior_account.present?

    prior = PriorAccount.create!(
      account_number: account_number,
      name: name || self.name,
      currency: currency
    )

    update!(prior_account: prior)
  end

  def disable_prior_sync!
    return unless prior_account.present?

    prior_account.destroy
  end
end
