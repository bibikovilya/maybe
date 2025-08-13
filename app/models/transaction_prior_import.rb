class TransactionPriorImport < TransactionImport
  after_initialize :set_defaults
  after_update :set_default_column_mappings, if: :saved_change_to_raw_file_str?

  DEFAULT_COLUMN_MAPPINGS = {
    date_col_label: "Дата транзакции",
    amount_col_label: "Сумма",
    name_col_label: "Операция",
    currency_col_label: "Валюта",
    category_col_label: "Категория операции"
  }.freeze

  def import!
    transaction do
      mappings.each(&:create_mappable!)

      transactions = parsed_transactions.map do |transaction_data|
        mapped_account = if account
          account
        else
          mappings.accounts.mappable_for(transaction_data[:account])
        end

        category = mappings.categories.mappable_for(transaction_data[:category])
        tags = transaction_data[:tags].map { |tag| mappings.tags.mappable_for(tag) }.compact

        Transaction.new(
          category: category,
          tags: tags,
          entry: Entry.new(
            account: mapped_account,
            date: transaction_data[:date],
            amount: transaction_data[:amount],
            name: transaction_data[:name],
            currency: transaction_data[:currency],
            notes: transaction_data[:notes],
            import: self
          )
        )
      end

      Transaction.import!(transactions, recursive: true)
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
    @csv_sample ||= parsed_csv.first(2) + parsed_csv[parsed_csv.length - 2..-1]
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
        self.class.parse_csv_str(transaction_lines.join("\n"), col_sep: ",")
      end
    end

    def extract_transaction_lines_as_csv
      lines = raw_file_str.split("\n")
      csv_lines = []
      in_transaction_section = false
      header_found = false

      lines.each do |line|
        if line.match(/^Операции по /)
          in_transaction_section = true
        elsif line.match(/^Дата транзакции,Операция,Сумма/)
          csv_lines << line unless header_found
          header_found = true
        elsif in_transaction_section && line.match(/^Всего по контракту/)
          in_transaction_section = false
        elsif in_transaction_section && line.strip.present? && line.include?(",")
          csv_lines << line
        end
      end

      csv_lines
    end
end
