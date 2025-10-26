class PriorAccount < ApplicationRecord
  has_one :account, dependent: :nullify

  validates :name, presence: true, uniqueness: true
  validates :currency, presence: true

  # Store the raw downloaded statement data
  def upsert_prior_snapshot!(statement_data)
    assign_attributes(
      current_balance: statement_data[:balance],
      currency: statement_data[:currency] || currency,
      name: statement_data[:name] || name,
      raw_payload: statement_data[:raw_data] || {}
    )

    save!
  end

  # Store raw transactions from downloaded statements
  def upsert_prior_transactions_snapshot!(transactions_data)
    assign_attributes(
      raw_transactions_payload: transactions_data
    )

    save!
  end

  # Update sync metadata
  def update_sync_metadata!(last_synced_at:, last_statement_date: nil)
    assign_attributes(
      last_synced_at: last_synced_at,
      last_statement_date: last_statement_date
    )

    save!
  end

  # Check if account needs syncing
  def needs_sync?
    return true if last_synced_at.nil?
    last_synced_at < 1.day.ago
  end

  # Get the date to start syncing from
  def sync_start_date
    last_statement_date || account&.start_date || 30.days.ago.to_date
  end
end
