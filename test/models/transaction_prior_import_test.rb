require "test_helper"

class TransactionPriorImportTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper, ImportInterfaceTest

  setup do
    @subject = @import = TransactionPriorImport.new(family: families(:dylan_family))
  end

  test "sets default configuration on initialization" do
    import = TransactionPriorImport.new(family: families(:dylan_family))

    # Check the actual database defaults first, then the TransactionPriorImport-specific defaults
    assert_equal "signed_amount", import.amount_type_strategy
    assert_equal "inflows_positive", import.signage_convention
    assert_equal "1.234,56", import.number_format
    # The date_format has a database default of "%m/%d/%Y", so after_initialize only sets if nil
    # Let's check that the method sets the right value when forced
    import.date_format = nil
    import.send(:set_defaults)
    assert_equal "%d.%m.%Y %H:%M:%S", import.date_format
  end

  test "sets default column mappings when raw_file_str is updated" do
    @import.update!(raw_file_str: sample_prior_csv)

    # Force the callback to run since we know the raw_file_str changed
    @import.send(:set_default_column_mappings)
    @import.reload

    assert_equal "Дата транзакции", @import.date_col_label
    assert_equal "Обороты по счету", @import.amount_col_label
    assert_equal "Операция", @import.name_col_label
    assert_equal "Валюта", @import.currency_col_label
    assert_equal "Notes", @import.notes_col_label
  end

  test "extracts transaction lines from complex CSV format" do
    @import.update!(
      raw_file_str: sample_prior_csv,
      date_col_label: "Дата транзакции",
      amount_col_label: "Сумма",
      name_col_label: "Операция",
      currency_col_label: "Валюта",
      notes_col_label: "Notes",
      date_format: "%d.%m.%Y %H:%M:%S"
    )
    @import.generate_rows_from_csv
    @import.reload

    assert @import.rows.any?, "Should have extracted some rows"
    # Check that it extracted transactions from the CSV
    transaction_row = @import.rows.find { |row| row.name.include?("Retail BLR Minsk") }
    assert transaction_row.present?, "Should extract transaction with 'Retail BLR Minsk' in name"
    assert_equal "29.03.2024 19:32:46", transaction_row.date
  end

  test "filters out duplicate transactions based on existing imports" do
    # Create an existing import with the same transaction
    existing_import = TransactionPriorImport.create!(
      family: families(:dylan_family),
      account: accounts(:depository),
      raw_file_str: sample_prior_csv,
      date_col_label: "Дата транзакции",
      amount_col_label: "Обороты по счету",
      name_col_label: "Операция",
      currency_col_label: "Валюта",
      notes_col_label: "Notes",
      date_format: "%d.%m.%Y %H:%M:%S"
    )
    existing_import.generate_rows_from_csv
    existing_import.reload
    existing_import.publish

    # Now create a new import with the same data
    @import.update!(
      account: accounts(:depository),
      raw_file_str: sample_prior_csv,
      date_col_label: "Дата транзакции",
      amount_col_label: "Обороты по счету",
      name_col_label: "Операция",
      currency_col_label: "Валюта",
      notes_col_label: "Notes",
      date_format: "%d.%m.%Y %H:%M:%S"
    )

    @import.generate_rows_from_csv
    @import.reload

    # Should have no rows since they're all duplicates
    assert_equal 0, @import.rows.count
  end

  test "handles money-back fees in amount calculation" do
    csv_with_fees = <<~CSV
      Операции по ........5333
      Дата транзакции,Операция,Сумма,Валюта,Дата операции по счету,Комиссия/Money-back,Обороты по счету,Цифровая карта,Категория операции,
      29.02.2024 19:05:54,Отправка SMS Monthly (CMC.PRO)  ,"0,00",USD,29.02.2024,"-1,08","-1,08",,,
      Всего по контракту,Зачислено,Списано,Комиссия/Money-back,Изменение баланса,
    CSV

    @import.update!(
      account: accounts(:depository),
      raw_file_str: csv_with_fees,
      date_col_label: "Дата транзакции",
      amount_col_label: "Обороты по счету",
      name_col_label: "Операция",
      currency_col_label: "Валюта",
      notes_col_label: "Notes",
      date_format: "%d.%m.%Y %H:%M:%S",
      number_format: "1.234,56"
    )

    @import.generate_rows_from_csv
    @import.reload

    row = @import.rows.find { |r| r.name.include?("Отправка SMS Monthly") }
    assert row.present?, "Should find test transaction row"
    assert_equal "0.0", row.amount
  end

  test "detects ATM withdrawals and creates transfers" do
    atm_csv = <<~CSV
      Операции по ........5333
      Дата транзакции,Операция,Сумма,Валюта,Дата операции по счету,Комиссия/Money-back,Обороты по счету,Цифровая карта,Категория операции,
      25.03.2024 12:29:59,ATM BLR MINSK PRIORBANK ATM 009  ,"-3 000,00",BYN,25.03.2024,"0,00","-3 000,00",,Снятие наличных,
      Всего по контракту,Зачислено,Списано,Комиссия/Money-back,Изменение баланса,
    CSV

    @import.update!(
      account: accounts(:depository),
      raw_file_str: atm_csv,
      date_col_label: "Дата транзакции",
      amount_col_label: "Обороты по счету",
      name_col_label: "Операция",
      currency_col_label: "Валюта",
      notes_col_label: "Notes",
      date_format: "%d.%m.%Y %H:%M:%S",
      number_format: "1.234,56"
    )

    @import.generate_rows_from_csv
    @import.reload

    # Count before
    initial_transfer_count = Transfer.count
    initial_account_count = Account.count

    @import.publish

    # Count after
    final_transfer_count = Transfer.count
    final_account_count = Account.count

    # 1 transfer should be created
    assert_equal 1, final_transfer_count - initial_transfer_count
    # 1 cash account should be created
    assert_equal 1, final_account_count - initial_account_count

    # Find the cash account that was created
    cash_account = Account.find_by(name: "Cash BYN")
    assert_not_nil cash_account

    # Find the transfer between our deposit account and the cash account
    transfer = Transfer.all.find { |t| t.from_account == accounts(:depository) && t.to_account == cash_account }
    assert_not_nil transfer, "Transfer from #{accounts(:depository).name} to #{cash_account.name} not found"

    # Verify transaction kinds
    assert_equal "funds_movement", transfer.outflow_transaction.kind
    assert_equal "funds_movement", transfer.inflow_transaction.kind
  end

  test "creates cash account for ATM withdrawals" do
    atm_csv = <<~CSV
      Операции по ........5333
      Дата транзакции,Операция,Сумма,Валюта,Дата операции по счету,Комиссия/Money-back,Обороты по счету,Цифровая карта,Категория операции,
      25.03.2024 12:29:59,ATM BLR MINSK PRIORBANK ATM 009  ,"-3 000,00",BYN,25.03.2024,"0,00","-3 000,00",,Снятие наличных,
      Всего по контракту,Зачислено,Списано,Комиссия/Money-back,Изменение баланса,
    CSV

    @import.update!(
      account: accounts(:depository),
      raw_file_str: atm_csv,
      date_col_label: "Дата транзакции",
      amount_col_label: "Обороты по счету",
      name_col_label: "Операция",
      currency_col_label: "Валюта",
      notes_col_label: "Notes",
      date_format: "%d.%m.%Y %H:%M:%S",
      number_format: "1.234,56"
    )

    @import.generate_rows_from_csv
    @import.reload

    assert_difference -> { Account.count } => 1 do
      @import.publish
    end

    cash_account = Account.order(:created_at).last
    assert_equal "Cash BYN", cash_account.name
    assert_equal "BYN", cash_account.currency
    assert_equal "asset", cash_account.classification
    assert_equal 0, cash_account.balance
    assert_equal 0, cash_account.cash_balance
    assert_instance_of Depository, cash_account.accountable
  end

  test "imports regular transactions and ATM transfers in same batch" do
    mixed_csv = <<~CSV
      Операции по ........5333
      Дата транзакции,Операция,Сумма,Валюта,Дата операции по счету,Комиссия/Money-back,Обороты по счету,Цифровая карта,Категория операции,
      25.03.2024 12:29:59,ATM BLR MINSK PRIORBANK ATM 009  ,"-3 000,00",BYN,25.03.2024,"0,00","-3 000,00",,Снятие наличных,
      26.03.2024 19:32:46,Retail BLR Minsk Gipermarket Gippo  ,"-29,88",BYN,29.03.2024,"0,00","-29,88",,Магазины продуктовые,
      27.03.2024 12:29:59,ATM BLR MINSK PRIORBANK ATM 009  ,"-1 000,00",BYN,25.03.2024,"0,00","-1 000,00",,Снятие наличных,
      Всего по контракту,Зачислено,Списано,Комиссия/Money-back,Изменение баланса,
    CSV

    @import.update!(
      account: accounts(:depository),
      raw_file_str: mixed_csv,
      date_col_label: "Дата транзакции",
      amount_col_label: "Обороты по счету",
      name_col_label: "Операция",
      currency_col_label: "Валюта",
      notes_col_label: "Notes",
      date_format: "%d.%m.%Y %H:%M:%S",
      number_format: "1.234,56"
    )

    @import.generate_rows_from_csv
    @import.reload

    assert_difference -> { Entry.count } => 5, # 4 for transfers (2*2) + 1 for regular transaction
                      -> { Transaction.count } => 5, # 4 for transfers + 1 for regular
                      -> { Transfer.count } => 2 do
      @import.publish
    end
  end

  test "adds notes column to CSV headers during parsing" do
    @import.update!(
      raw_file_str: sample_prior_csv,
      date_col_label: "Дата транзакции",
      amount_col_label: "Сумма",
      name_col_label: "Операция",
      currency_col_label: "Валюта",
      notes_col_label: "Notes",
      date_format: "%d.%m.%Y %H:%M:%S"
    )
    @import.generate_rows_from_csv
    @import.reload

    # Verify that notes were added and contain the full transaction line
    row = @import.rows.find { |r| r.name.include?("Retail BLR Minsk") }
    assert row.present?, "Should find transaction row"
    assert row.notes.present?
    assert row.notes.include?("Retail BLR Minsk Gipermarket Gippo")
  end

  test "returns custom CSV template" do
    template = @import.csv_template

    assert_instance_of CSV::Table, template
    # The template should be parseable and contain some sample data
    assert template.length > 0, "Template should have sample rows"
    # Check if any of the sample data contains Cyrillic text
    template_str = template.to_csv
    assert template_str.include?("Дата транзакции") || template_str.include?("BYN"), "Template should contain Cyrillic headers or BYN currency"
  end

  test "csv_sample returns limited rows for preview" do
    @import.update!(
      raw_file_str: sample_prior_csv,
      date_col_label: "Дата транзакции",
      amount_col_label: "Обороты по счету",
      name_col_label: "Операция",
      currency_col_label: "Валюта",
      notes_col_label: "Notes",
      date_format: "%d.%m.%Y %H:%M:%S"
    )
    @import.generate_rows_from_csv

    sample = @import.csv_sample
    assert sample.length <= 4
  end

  test "handles empty CSV gracefully" do
    @import.update!(raw_file_str: "")
    @import.generate_rows_from_csv

    assert_equal 0, @import.rows.count
  end

  test "handles CSV with only headers" do
    headers_only = <<~CSV
      Операции по ........5333
      Дата транзакции,Операция,Сумма,Валюта,Дата операции по счету,Комиссия/Money-back,Обороты по счету,Цифровая карта,Категория операции,
      Всего по контракту,Зачислено,Списано,Комиссия/Money-back,Изменение баланса,
    CSV

    @import.update!(
      raw_file_str: headers_only,
      date_col_label: "Дата транзакции",
      amount_col_label: "Обороты по счету",
      name_col_label: "Операция",
      currency_col_label: "Валюта",
      notes_col_label: "Notes",
      date_format: "%d.%m.%Y %H:%M:%S"
    )

    @import.generate_rows_from_csv
    assert_equal 0, @import.rows.count
  end

  test "properly inherits mapping steps from parent" do
    # Without account, should include account mapping
    import_without_account = TransactionPriorImport.new(family: families(:dylan_family))
    expected_steps = [ Import::CategoryMapping, Import::TagMapping, Import::AccountMapping ]
    assert_equal expected_steps, import_without_account.mapping_steps

    # With account, should not include account mapping
    import_with_account = TransactionPriorImport.new(family: families(:dylan_family), account: accounts(:depository))
    expected_steps = [ Import::CategoryMapping, Import::TagMapping ]
    assert_equal expected_steps, import_with_account.mapping_steps
  end

  test "inherits required_column_keys from parent" do
    assert_equal %i[date amount], @import.required_column_keys
  end

  test "inherits column_keys behavior from parent" do
    # Without account
    import_without_account = TransactionPriorImport.new(family: families(:dylan_family))
    expected_keys = %i[account date amount name currency category tags notes]
    assert_equal expected_keys, import_without_account.column_keys

    # With account
    import_with_account = TransactionPriorImport.new(family: families(:dylan_family), account: accounts(:depository))
    expected_keys = %i[date amount name currency category tags notes]
    assert_equal expected_keys, import_with_account.column_keys
  end

  private

    def sample_prior_csv
      <<~CSV
        Выписка по контракту
        Период выписки:,01.04.2024-30.06.2024,
        Дата выписки:,17.08.2024 18:50:30,
        Адрес страницы в интернете:,https://www.prior.by/web/Cabinet/BankCards/,
        Номер контракта:,......3670 Валюта контракта BYN,
        Карта:,........0343 VISA VIRTUAL ,
        ФИО:, Илья Бибиков,
        Адрес:,"220000",

        Доступная сумма:,"16,44",
        Заблокировано:,"3,80",
        Кредитный лимит:,"0,00",

        Валюта счета: ,BYN,
        Начальный баланс: ,"37,23"

        Операции по ........9090
        Дата транзакции,Операция,Сумма,Валюта,Дата операции по счету,Комиссия/Money-back,Обороты по счету,Цифровая карта,Категория операции,
        25.03.2024 00:00:00,Поступление на контракт клиента 749114-00081-032913  ,"900,00",BYN,25.03.2024,"0,00","900,00",,,
        Всего по контракту,Зачислено,Списано,Комиссия/Money-back,Изменение баланса,
        ,"628,00","614,89","-10,50","2,61",

        Операции по ........5333
        Дата транзакции,Операция,Сумма,Валюта,Дата операции по счету,Комиссия/Money-back,Обороты по счету,Цифровая карта,Категория операции,
        29.03.2024 19:32:46,Retail BLR Minsk Gipermarket Gippo  ,"-29,88",BYN,29.03.2024,"0,00","-29,88",,Магазины продуктовые,
        29.03.2024 10:48:27,CH Debit BLR MINSK P2P SDBO NO FEE  ,"-50,00",BYN,29.03.2024,"0,00","-50,00",,Переводы с карты на карту,
        Всего по контракту,Зачислено,Списано,Комиссия/Money-back,Изменение баланса,
        ,"628,00","614,89","-10,50","39,84",

        Заблокированные суммы по ........0343
        Дата транзакции,Транзакция,Сумма транзакции,Валюта,Сумма блокировки,Валюта,Цифровая карта,Категория операции,
        15.08.2024 14:51:04,Retail BLR MINSK ROSE CAFE,"14,80",BYN,"14,80",BYN,,Ресторация / бары / кафе,
      CSV
    end
end
