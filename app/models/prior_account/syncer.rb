class PriorAccount::Syncer
  attr_reader :account, :prior_account, :sync

  def initialize(prior_account)
    @prior_account = prior_account
    @account = prior_account.account
  end

  def perform_sync(sync)
    @sync = sync
    sync_update("start", "Starting Priorbank account #{account.id} - #{account.name} sync...")

    csv_data = fetch_transactions
    import_transactions(csv_data)

    import_market_data
    materialize_balances

    sync_update("complete", "Sync completed successfully!", "success")
  end

  def perform_post_sync
    sync_update("post_sync", "Performing post-sync auto match transfers...")
    account.family.auto_match_transfers!
    sync_update("post_sync", "Post-sync operations completed", "success")
  end

  private

    def sync_update(step, message, status = "in_progress")
      Rails.logger.info "[PriorAccount::Syncer] Sync update - Step: #{step}, Message: #{message}, Status: #{status}"
      sync.progress_update(step: step, message: message, status: status)
    end

    def fetch_transactions
      window_start = sync.window_start_date || account.entries.maximum(:date) || 3.months.ago.to_date
      window_end = sync.window_end_date || [ account.entries.maximum(:date) + 3.months, Date.current ].min

      sync_update("fetch_transactions", "Fetching transactions from #{window_start.strftime('%d.%m.%Y')} to #{window_end.strftime('%d.%m.%Y')}...")

      downloader = PriorAccount::StatementDownloader.new(
        window_start,
        window_end,
        prior_account.name,
        headless: true,
        sync: sync
      )
      csv_file_path = downloader.call

      sync_update("fetch_transactions", "Fixing the downloaded file encoding #{csv_file_path}...")
      fixed_csv_data = Utils::CsvEncodingFixer.convert_file(csv_file_path)
      sync_update("fetch_transactions", "Downloaded file encoding fixed", "success")

      downloader.teardown
      fixed_csv_data
    rescue => e
      sync_update("fetch_transactions", "Error fetching transactions: #{e.message}", "error")
      raise
    end

    def import_transactions(csv_data)
      sync_update("import_transactions", "Importing transactions...")

      import = account.family.imports.create!(
        type: "TransactionPriorImport",
        account: account,
        raw_file_str: csv_data
      )
      import.set_defaults
      import.set_default_column_mappings
      sync_update("import_transactions", "Generating rows from CSV data...")
      import.generate_rows_from_csv
      sync_update("import_transactions", "Syncing mappings...")
      import.reload.sync_mappings
      sync_update("import_transactions", "Publishing the import...")
      import.reload.publish

      sync_update("import_transactions", "Successfully imported #{import.rows.count} transactions", "success")

      import
    rescue => e
      sync_update("import_transactions", "Error importing transactions: #{e.message}", "error")
      raise
    end

    def import_market_data
      sync_update("market_data", "Importing market data...")
      Account::MarketDataImporter.new(account).import_all
      sync_update("market_data", "Market data imported", "success")
    rescue => e
      sync_update("market_data", "Error syncing market data for account #{account.id}: #{e.message}", "error")
      Sentry.capture_exception(e)
    end

    def materialize_balances
      sync_update("balances", "Calculating balances...")
      strategy = account.linked? ? :reverse : :forward
      Balance::Materializer.new(account, strategy: strategy).materialize_balances
      sync_update("balances", "Balances calculated", "success")
    end
end
