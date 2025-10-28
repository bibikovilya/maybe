class PriorAccount::Syncer
  attr_reader :account, :prior_account

  def initialize(prior_account)
    @prior_account = prior_account
    @account = prior_account.account
  end

  def perform_sync(sync)
    Rails.logger.info("Starting Priorbank sync for account #{account.id}")

    csv_data = fetch_transactions(sync)
    import_transactions(csv_data)

    import_market_data
    materialize_balances
  end

  def perform_post_sync
    account.family.auto_match_transfers!
  end

  private

    def fetch_transactions(sync)
      window_start = sync.window_start_date || account.entries.maximum(:date) || 3.months.ago.to_date
      window_end = sync.window_end_date || [ account.entries.maximum(:date) + 3.months, Date.current ].min

      Rails.logger.info("Scraping Priorbank transactions from #{window_start} to #{window_end}")

      downloader = PriorAccount::StatementDownloader.new(
        window_start,
        window_end,
        prior_account.name,
        headless: true
      )
      csv_file_path = downloader.call

      Rails.logger.info("Fixing the downloaded file encoding #{csv_file_path}")
      fixed_csv_data = Utils::CsvEncodingFixer.convert_file(csv_file_path)

      downloader.teardown
      fixed_csv_data
    rescue => e
      Rails.logger.error("Priorbank sync error for account #{account.id}: #{e.message}")
      raise
    end

    def import_transactions(csv_data)
      Rails.logger.info("Importing Priorbank statements for #{account.id}")

      import = account.family.imports.create!(
        type: "TransactionPriorImport",
        account: account,
        raw_file_str: csv_data
      )
      import.set_defaults
      import.set_default_column_mappings
      import.generate_rows_from_csv
      import.reload.sync_mappings
      import.reload.publish

      Rails.logger.info("Successfully imported #{import.rows.count} transactions for account #{account.id}")

      import
    rescue => e
      Rails.logger.error("Failed to import Priorbank transactions for account #{account.id}: #{e.message}")
      raise
    end

    def import_market_data
      Account::MarketDataImporter.new(account).import_all
    rescue => e
      Rails.logger.error("Error syncing market data for account #{account.id}: #{e.message}")
      Sentry.capture_exception(e)
    end

    def materialize_balances
      strategy = account.linked? ? :reverse : :forward
      Balance::Materializer.new(account, strategy: strategy).materialize_balances
    end
end
