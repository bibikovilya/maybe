class TransactionPriorImport < Import
  after_initialize :set_defaults

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

  def required_column_keys
    %i[date amount]
  end

  def column_keys
    base = %i[date amount name currency category tags notes]
    base.unshift(:account) if account.nil?
    base
  end

  def mapping_steps
    base = [ Import::CategoryMapping, Import::TagMapping ]
    base << Import::AccountMapping if account.nil?
    base
  end

  def generate_rows_from_csv
    rows.destroy_all

    mapped_rows = parsed_transactions.map do |tx|
      {
        import_id: id,
        account: tx[:account],
        date: tx[:date].strftime("%d.%m.%Y"),
        amount: tx[:amount].to_s,
        currency: tx[:currency],
        name: tx[:name],
        category: tx[:category],
        tags: tx[:tags].join("|"),
        notes: tx[:notes]
      }
    end

    Import::Row.insert_all!(mapped_rows) if mapped_rows.any?
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

  def date_format
    "%d.%m.%Y"
  end

  private

    def set_defaults
      self.amount_type_strategy ||= "signed_amount"
      self.signage_convention ||= "inflows_negative"
      self.number_format ||= "1.234,56"  # European format for BYN
    end

    def parsed_transactions
      @parsed_transactions ||= parse_belarusian_bank_statement
    end

    def parse_belarusian_bank_statement
      transactions = []
      lines = raw_file_str.split("\n")

      # Find the main transactions section (operations by card)
      operation_sections = find_operation_sections(lines)

      operation_sections.each do |section|
        transactions.concat(parse_operation_section(section))
      end

      transactions
    end

    def find_operation_sections(lines)
      sections = []
      current_section = nil
      in_transaction_section = false

      lines.each_with_index do |line, index|
        # Look for operation section headers like "Операции по ........5333"
        if line.match(/^Операции по/)
          current_section = {
            header: line,
            start_index: index,
            lines: []
          }
          in_transaction_section = false
          next
        end

        # Look for the transaction header row
        if current_section && line.include?("Дата транзакции,Операция,Сумма")
          in_transaction_section = true
          current_section[:header_row] = line
          next
        end

        # Look for section end (summary line starting with "Всего по контракту")
        if in_transaction_section && line.match(/^Всего по контракту/)
          sections << current_section if current_section
          current_section = nil
          in_transaction_section = false
          next
        end

        # Collect transaction lines
        if in_transaction_section && current_section && line.strip.present? && line.include?(",")
          current_section[:lines] << line
        end
      end

      sections
    end

    def parse_operation_section(section)
      transactions = []

      section[:lines].each do |line|
        # Skip empty lines and summary lines
        next if line.strip.blank? || line.match(/^Всего/)

        # Parse CSV line - handling commas in quoted fields
        begin
          # Split by comma, but respect quoted fields
          fields = CSV.parse_line(line)
          next if fields.nil? || fields.length < 5

          date_str = fields[0]&.strip
          operation = fields[1]&.strip
          amount_str = fields[2]&.strip
          currency = fields[3]&.strip
          category = fields[8]&.strip if fields.length > 8 # Category is in column 9

          # Skip if essential fields are missing
          next if date_str.blank? || amount_str.blank?

          # Parse date - handle format "01.02.2024 14:44:55" or "01.02.2024 00:00:00"
          date = parse_belarusian_date(date_str)
          next unless date

          # Parse amount - handle format like "-1,99" or "900,00"
          amount = parse_belarusian_amount(amount_str)
          next unless amount

          # Extract account from section header (last 4 digits)
          account_number = extract_account_from_header(section[:header])

          transactions << {
            date: date,
            amount: amount,
            name: operation || "Банковская операция",
            currency: currency || "BYN",
            category: category || "",
            account: account_number,
            tags: [],
            notes: ""
          }
        rescue CSV::MalformedCSVError
          # Skip malformed lines
          next
        end
      end

      transactions
    end

    def parse_belarusian_date(date_str)
      # Handle formats like "01.02.2024 14:44:55" or "31.01.2024 00:00:00"
      return nil if date_str.blank?

      # Extract just the date part
      date_part = date_str.split(" ").first

      begin
        Date.strptime(date_part, "%d.%m.%Y")
      rescue ArgumentError
        nil
      end
    end

    def parse_belarusian_amount(amount_str)
      return nil if amount_str.blank?

      # Remove quotes and handle comma as decimal separator
      amount_str = amount_str.gsub(/["']/, "").strip

      # Replace comma with dot for decimal separator
      amount_str = amount_str.gsub(",", ".")

      # Remove spaces (used as thousands separator in some formats)
      amount_str = amount_str.gsub(/\s+/, "")

      begin
        BigDecimal(amount_str)
      rescue ArgumentError
        nil
      end
    end

    def extract_account_from_header(header)
      # Extract account number from header like "Операции по ........5333"
      match = header.match(/\.+(\d{4})/)
      if match
        "****#{match[1]}"
      else
        "Unknown Account"
      end
    end
end
