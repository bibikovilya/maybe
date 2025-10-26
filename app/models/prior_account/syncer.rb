class PriorAccount::Syncer
  attr_reader :account, :prior_account

  def initialize(prior_account)
    @account = prior_account.account
    @prior_account = prior_account
  end

  def perform_sync(sync)
    Rails.logger.info("Starting Priorbank sync for account #{account.id}")

    # fetch_and_import_transactions(sync)

    # Update sync metadata
    # account.update_priorbank_sync_metadata!(
    #   last_synced_at: Time.current,
    #   last_statement_date: sync.window_end_date || Date.current
    # )

    # After importing, recalculate balances
    # materialize_balances
  end

  def perform_post_sync
    # account.family.auto_match_transfers!
  end

  private

    def fetch_and_import_transactions(sync)
      window_start = sync.window_start_date || account.start_date
      window_end = sync.window_end_date || Date.current

      Rails.logger.info("Fetching Priorbank transactions from #{window_start} to #{window_end}")

      # Download statements for each month in the window
      months = (window_start..window_end).map { |d| d.beginning_of_month }.uniq

      months.each do |month|
        download_and_import_month(month)
      end
    rescue => e
      Rails.logger.error("Priorbank sync error for account #{account.id}: #{e.message}")
      raise Sync::Error, "Failed to sync Priorbank transactions: #{e.message}"
    end

    def download_and_import_month(month)
      Rails.logger.info("Downloading Priorbank statements for #{month.strftime('%B %Y')}")

      # Create temporary download directory
      download_path = Rails.root.join("tmp", "priorbank_downloads", account.id.to_s, month.strftime("%Y%m"))
      FileUtils.mkdir_p(download_path)

      begin
        # Download statements using headless browser
        downloader = Priorbank::StatementDownloader.new(month, download_path.to_s, headless: true)
        csv_files = downloader.call

        Rails.logger.info("Downloaded #{csv_files.count} statement files")

        # Import each CSV file
        csv_files.each do |csv_file|
          import_csv_file(csv_file)
        end
      ensure
        # Clean up downloaded files
        FileUtils.rm_rf(download_path) if download_path.exist?
      end
    end

    def import_csv_file(csv_file_path)
      Rails.logger.info("Importing transactions from #{File.basename(csv_file_path)}")

      csv_data = File.read(csv_file_path)
      service = Priorbank::ManualSyncService.new(account, csv_data)
      results = service.sync

      Rails.logger.info("Import results: Created #{results[:created]}, Skipped #{results[:skipped]}, Errors #{results[:errors].count}")

      results[:errors].each do |error|
        Rails.logger.warn("Import error: #{error[:error]}")
      end
    end

    def materialize_balances
      strategy = account.linked? ? :reverse : :forward
      Balance::Materializer.new(account, strategy: strategy).materialize_balances
    end
end
