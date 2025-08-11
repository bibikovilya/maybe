require "test_helper"
require "ostruct"

class Provider::NbrbTest < ActiveSupport::TestCase
  include ExchangeRateProviderInterfaceTest

  setup do
    @subject = @nbrb = Provider::Nbrb.new
  end

  test "health check" do
    VCR.use_cassette("nbrb/health") do
      assert @nbrb.healthy?
    end
  end

  test "fetches exchange rate from foreign currency to BYN" do
    VCR.use_cassette("nbrb/usd_to_byn") do
      response = @nbrb.fetch_exchange_rate(
        from: "USD",
        to: "BYN",
        date: Date.parse("2024-01-10")
      )

      assert response.success?
      rate = response.data
      assert_equal "USD", rate.from
      assert_equal "BYN", rate.to
      assert rate.rate.is_a?(Numeric)
      assert rate.rate > 0
    end
  end

  test "fetches exchange rate from BYN to foreign currency" do
    VCR.use_cassette("nbrb/byn_to_usd") do
      response = @nbrb.fetch_exchange_rate(
        from: "BYN",
        to: "USD",
        date: Date.parse("2024-01-10")
      )

      assert response.success?
      rate = response.data
      assert_equal "BYN", rate.from
      assert_equal "USD", rate.to
      assert rate.rate.is_a?(Numeric)
      assert rate.rate > 0
    end
  end

  test "fetches cross exchange rate between two foreign currencies" do
    VCR.use_cassette("nbrb/usd_to_eur_cross") do
      response = @nbrb.fetch_exchange_rate(
        from: "USD",
        to: "EUR",
        date: Date.parse("2024-01-10")
      )

      assert response.success?
      rate = response.data
      assert_equal "USD", rate.from
      assert_equal "EUR", rate.to
      assert rate.rate.is_a?(Numeric)
      assert rate.rate > 0
    end
  end

  test "fetches multiple exchange rates using dynamics endpoint" do
    VCR.use_cassette("nbrb/usd_to_byn_dynamics") do
      response = @nbrb.fetch_exchange_rates(
        from: "USD",
        to: "BYN",
        start_date: Date.parse("2024-01-10"),
        end_date: Date.parse("2024-01-15")
      )

      assert response.success?
      rates = response.data
      assert rates.is_a?(Array)
      assert rates.length > 0

      rates.each do |rate|
        assert_equal "USD", rate.from
        assert_equal "BYN", rate.to
        assert rate.rate.is_a?(Numeric)
        assert rate.rate > 0
        assert rate.date.is_a?(Date)
      end
    end
  end

  test "handles invalid currency gracefully" do
    VCR.use_cassette("nbrb/invalid_currency") do
      response = @nbrb.fetch_exchange_rate(
        from: "INVALID",
        to: "BYN",
        date: Date.parse("2024-01-10")
      )

      assert_not response.success?
      assert response.error.present?
    end
  end
end
