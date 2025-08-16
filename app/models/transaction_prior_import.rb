class TransactionPriorImport < TransactionImport
  after_initialize :set_defaults
  after_update :set_default_column_mappings, if: :saved_change_to_raw_file_str?

  NOTES_HEADER = "Notes".freeze
  DEFAULT_COLUMN_MAPPINGS = {
    date_col_label: "Дата транзакции",
    amount_col_label: "Сумма",
    name_col_label: "Операция",
    currency_col_label: "Валюта",
    notes_col_label: NOTES_HEADER
  }.freeze
  FILE_LINES = {
    transaction_start: "Операции по ",
    headers: "Дата транзакции,Операция,Сумма,Валюта",
    transaction_end: "Всего по контракту"
  }

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
end
