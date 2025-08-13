require "test_helper"

class TransactionPriorImportTest < ActiveSupport::TestCase
  setup do
    @family = families(:dylan_family)
    @import = TransactionPriorImport.create!(family: @family)
  end

  test "parses Prior bank statement format" do
    bank_statement = <<~CSV
      Выписка по контракту
      Период выписки:,01.01.2024-01.02.2024,
      Дата выписки:,06.08.2024 21:52:11,
      Адрес страницы в интернете:,https://www.prior.by/web/Cabinet/BankCards/,
      Номер контракта:,......9090 Валюта контракта BYN,
      Карта:,........5333 VISA GOLD ,
      ФИО:, Илья Бибиков,

      Операции по ........5333
      Дата транзакции,Операция,Сумма,Валюта,Дата операции по счету,Комиссия/Money-back,Обороты по счету,Цифровая карта,Категория операции,
      01.02.2024 14:44:55,Retail BLR Minsk Gipermarket Gippo  ,"-1,99",BYN,01.02.2024,"0,00","-1,99",,Магазины продуктовые,
      31.01.2024 14:10:59,Retail BLR MINSK MOBILE BANK  ,"-60,19",BYN,31.01.2024,"0,00","-60,19",,Денежные переводы,
      31.01.2024 13:50:42,CH Debit BLR MINSK P2P SDBO NO FEE  ,"-20,00",BYN,31.01.2024,"0,00","-20,00",,Переводы с карты на карту,
      Всего по контракту,Зачислено,Списано,Комиссия/Money-back,Изменение баланса,
      ,"199,00","8 699,11","0,00","-8 500,11",
    CSV

    @import.update!(raw_file_str: bank_statement)
    @import.generate_rows_from_csv
    @import.reload

    assert_equal 3, @import.rows.count

    # Find the specific transaction we want to test
    gippo_row = @import.rows.find { |r| r.name.include?("Gipermarket Gippo") }
    assert_not_nil gippo_row
    assert_equal "01.02.2024", gippo_row.date
    assert_equal "-1.99", gippo_row.amount
    assert_equal "Retail BLR Minsk Gipermarket Gippo", gippo_row.name.strip
    assert_equal "BYN", gippo_row.currency
    assert_equal "Магазины продуктовые", gippo_row.category
    assert_equal "****5333", gippo_row.account
  end

  test "handles multiple card sections" do
    bank_statement = <<~CSV
      Операции по ........9090
      Дата транзакции,Операция,Сумма,Валюта,Дата операции по счету,Комиссия/Money-back,Обороты по счету,Цифровая карта,Категория операции,
      31.01.2024 00:00:00,Поступление на контракт клиента 749114-00081-032913  ,"900,00",BYN,25.01.2024,"0,00","900,00",,,
      Всего по контракту,Зачислено,Списано,Комиссия/Money-back,Изменение баланса,

      Операции по ........5333
      Дата транзакции,Операция,Сумма,Валюта,Дата операции по счету,Комиссия/Money-back,Обороты по счету,Цифровая карта,Категория операции,
      01.02.2024 14:44:55,Retail BLR Minsk Gipermarket Gippo  ,"-1,99",BYN,01.02.2024,"0,00","-1,99",,Магазины продуктовые,
      Всего по контракту,Зачислено,Списано,Комиссия/Money-back,Изменение баланса,
    CSV

    @import.update!(raw_file_str: bank_statement)
    @import.generate_rows_from_csv
    @import.reload

    assert_equal 2, @import.rows.count

    # Check first transaction from contract 9090
    income_row = @import.rows.find { |r| r.amount.to_f > 0 }
    assert_equal "9090", income_row.account
    assert_equal "900.0", income_row.amount

    # Check transaction from contract 5333
    expense_row = @import.rows.find { |r| r.amount.to_f < 0 }
    assert_equal "****5333", expense_row.account
    assert_equal "-1.99", expense_row.amount
  end
end
