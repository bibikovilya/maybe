class TransactionPriorImport < TransactionImport
  after_initialize :set_defaults
  after_update :set_default_column_mappings, if: :saved_change_to_raw_file_str?

  NOTES_HEADER = "Notes".freeze
  DEFAULT_COLUMN_MAPPINGS = {
    date_col_label: "Дата транзакции",
    amount_col_label: "Обороты по счету",
    name_col_label: "Операция",
    currency_col_label: "Валюта",
    notes_col_label: NOTES_HEADER
  }.freeze
  FEE_COL_LABEL = "Комиссия/Money-back".freeze
  WITHDRAW_PATTERN = "Снятие наличных".freeze
  FILE_LINES = {
    transaction_start: "Операции по ",
    headers: "Дата транзакции,Операция,Сумма,Валюта",
    transaction_end: "Всего по контракту"
  }

  # Override the parent import! method to handle ATM transfers
  def import!
    transaction do
      mappings.each(&:create_mappable!)

      transactions = []
      transfers = []

      rows.each do |row|
        mapped_account = if account
          account
        else
          mappings.accounts.mappable_for(row.account)
        end

        category = mappings.categories.mappable_for(row.category)
        tags = row.tags_list.map { |tag| mappings.tags.mappable_for(tag) }.compact

        if atm_withdrawal?(row)
          transfers << create_atm_transfer(
            from_account: mapped_account,
            to_account: find_or_create_cash_account(row.currency),
            date: row.date_iso,
            amount: row.signed_amount.abs,
            name: row.name,
            currency: mapped_account.currency,
            notes: row.notes,
            import: self
          )
        else
          transactions << Transaction.new(
            category: category,
            tags: tags,
            entry: Entry.new(
              account: mapped_account,
              date: row.date_iso,
              amount: row.signed_amount,
              name: row.name,
              currency: mapped_account.currency,
              notes: row.notes,
              import: self
            )
          )
        end
      end

      Transaction.import!(transactions, recursive: true) if transactions.any?
      Transfer.import!(transfers, recursive: true) if transfers.any?
    end
  end

  def csv_template
    template = <<-CSV
      Операции по ........9090
      Дата транзакции,Операция,Сумма,Валюта,Дата операции по счету,Комиссия/Money-back,Обороты по счету,Цифровая карта,Категория операции,
      10.01.2024 00:00:00,Поступление на контракт клиента 749114-00081-032913  ,"10 282,71",BYN,10.01.2024,"0,00","10 282,71",,,
      Всего по контракту,Зачислено,Списано,Комиссия/Money-back,Изменение баланса,
      ,"10 282,71","0,00","0,00","10 282,71",

      Операции по ........5333
      Дата транзакции,Операция,Сумма,Валюта,Категория операции
      01.01.2024 14:44:55,Retail BLR Minsk Gipermarket Gippo,-1.99,BYN,Магазины продуктовые
      31.01.2024 14:10:59,Retail BLR MINSK MOBILE BANK,-60.19,BYN,Денежные переводы
      Всего по контракту,Зачислено,Списано,Комиссия/Money-back,Изменение баланса,
      ,"0,00","0,00","0,00","-62,18",
    CSV

    CSV.parse(template, headers: true)
  end

  def csv_sample
    @csv_sample ||= begin
      return [] if parsed_csv.empty?

      if parsed_csv.length <= 4
        parsed_csv
      else
        parsed_csv.first(2) + parsed_csv[parsed_csv.length - 2..-1]
      end
    end
  end

  # Override the amount to consider money-back fees
  def generate_rows_from_csv
    rows.destroy_all

    mapped_rows = csv_rows.map do |row|
      {
        account: row[account_col_label].to_s,
        date: row[date_col_label].to_s,
        qty: sanitize_number(row[qty_col_label]).to_s,
        ticker: row[ticker_col_label].to_s,
        exchange_operating_mic: row[exchange_operating_mic_col_label].to_s,
        price: sanitize_number(row[price_col_label]).to_s,
        amount: (sanitize_number(row[amount_col_label]).to_f - sanitize_number(row[FEE_COL_LABEL]).to_f).to_s,
        currency: (row[currency_col_label] || default_currency).to_s,
        name: (row[name_col_label] || default_row_name).to_s,
        category: row[category_col_label].to_s,
        tags: row[tags_col_label].to_s,
        entity_type: row[entity_type_col_label].to_s,
        notes: row[notes_col_label].to_s,
        opening_date: row[opening_date_col_label].to_s
      }
    end

    rows.insert_all!(mapped_rows)
  end

  private

    def set_defaults
      self.amount_type_strategy ||= "signed_amount"
      self.signage_convention ||= "inflows_negative"
      self.number_format ||= "1.234,56"
      self.date_format ||= "%d.%m.%Y %H:%M:%S"
    end

    def set_default_column_mappings
      return unless csv_headers.present?

      transaction do
        DEFAULT_COLUMN_MAPPINGS.each do |column_attr, header_name|
          if csv_headers.include?(header_name) && public_send(column_attr).blank?
            assign_attributes(column_attr => header_name)
          end
        end
        save!
      end
    end

    def parsed_csv
      @parsed_csv ||= begin
        transaction_lines = extract_transaction_lines_as_csv
        transaction_lines = filter_duplicate_transactions(transaction_lines)
        transaction_lines = add_notes(transaction_lines)
        self.class.parse_csv_str(transaction_lines.join("\n"), col_sep: ",")
      end
    end

    def filter_duplicate_transactions(transaction_lines)
      transaction_lines.reject do |line|
        existing_transactions.include?(line.gsub("\"", "").strip)
      end
    end

    def existing_transactions
      @existing_transactions ||= begin
        target_accounts = if account
          [ account ]
        else
          family.accounts
        end

        existing_entries = Entry.joins(:import)
                                .where(account: target_accounts, imports: { type: "TransactionPriorImport" })
                                .where.not(imports: { id: self.id })
                                .pluck(:notes)

        existing_entries.compact.to_set
      end
    end

    def extract_transaction_lines_as_csv
      lines = raw_file_str.split("\n")
      csv_lines = []
      in_transaction_section = false
      header_found = false

      lines.each do |line|
        if line.start_with?(FILE_LINES[:transaction_start])
          in_transaction_section = true
        elsif line.start_with?(FILE_LINES[:headers])
          csv_lines << line unless header_found
          header_found = true
        elsif in_transaction_section && line.match(/^#{FILE_LINES[:transaction_end]}/)
          in_transaction_section = false
        elsif in_transaction_section && line.strip.present? && line.include?(",")
          csv_lines << line
        end
      end

      csv_lines
    end

    def add_notes(transaction_lines)
      transaction_lines.each do |line|
        line.chomp!("\r")
        if line.start_with?(FILE_LINES[:headers])
          line << NOTES_HEADER
        else
          line << "\"#{line.gsub("\"", "")}\""
        end
        line << "\r"
      end
    end

    def atm_withdrawal?(row)
      row.notes.match?(WITHDRAW_PATTERN)
    end

    def find_or_create_cash_account(currency)
      account_name = "Cash #{currency.upcase}"

      family.accounts.find_or_create_by!(name: account_name) do |new_account|
        new_account.balance = 0
        new_account.cash_balance = 0
        new_account.currency = currency
        new_account.accountable = Depository.new
        new_account.classification = "asset"
        new_account.import = self
      end
    end

    def create_atm_transfer(from_account:, to_account:, amount:, date:, currency:, name:, notes:, import:)
      outflow_transaction = Transaction.create!(
        kind: "funds_movement",
        entry: Entry.new(
          account: from_account,
          date:,
          amount:,
          currency:,
          name:,
          notes:,
          import:
        )
      )
      inflow_transaction = Transaction.create!(
        kind: "funds_movement",
        entry: Entry.new(
          account: to_account,
          date:,
          amount: -amount,
          currency:,
          name: "Cash from #{from_account.name}",
          import:
        )
      )
      Transfer.new(
        outflow_transaction:,
        inflow_transaction:,
        status: "confirmed"
      )
    end
end
