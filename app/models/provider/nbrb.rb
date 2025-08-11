class Provider::Nbrb < Provider
  include ExchangeRateConcept

  # Subclass so errors caught in this provider are raised as Provider::Nbrb::Error
  Error = Class.new(Provider::Error)
  InvalidExchangeRateError = Class.new(Error)

  def healthy?
    with_provider_response do
      response = client.get("#{base_url}/exrates/rates", periodicity: 0)
      parsed = JSON.parse(response.body)
      parsed.is_a?(Array) && parsed.any?
    end
  end

  # ================================
  #          Exchange Rates
  # ================================

  def fetch_exchange_rate(from:, to:, date:)
    with_provider_response do
      if to.upcase == "BYN"
        # Fetching rate TO Belarusian Ruble
        rate_data = fetch_rate_to_byn(from, date)
        Rate.new(date: date.to_date, from:, to:, rate: rate_data[:rate])
      elsif from.upcase == "BYN"
        # Fetching rate FROM Belarusian Ruble
        rate_data = fetch_rate_to_byn(to, date)
        # Inverse the rate since NBRB gives us BYN/foreign, but we need foreign/BYN
        Rate.new(date: date.to_date, from:, to:, rate: 1.0 / rate_data[:rate])
      else
        # Cross rate calculation: both currencies are foreign to BYN
        from_rate_data = fetch_rate_to_byn(from, date)
        to_rate_data = fetch_rate_to_byn(to, date)

        # Calculate cross rate: from_currency/to_currency
        # If USD = 3 BYN and GBP = 4 BYN, then USD/GBP = 3/4 = 0.75
        cross_rate = from_rate_data[:rate] / to_rate_data[:rate]
        Rate.new(date: date.to_date, from:, to:, rate: cross_rate)
      end
    end
  end

  def fetch_exchange_rates(from:, to:, start_date:, end_date:)
    with_provider_response do
      if to.upcase == "BYN"
        # Fetching rates TO Belarusian Ruble using dynamics endpoint
        fetch_rates_to_byn_dynamics(from, start_date, end_date)
      elsif from.upcase == "BYN"
        # Fetching rates FROM Belarusian Ruble (inverse rates)
        byn_rates = fetch_rates_to_byn_dynamics(to, start_date, end_date)
        byn_rates.map do |rate|
          Rate.new(
            date: rate.date,
            from: from,
            to: to,
            rate: 1.0 / rate.rate
          )
        end
      else
        # Cross rates between two foreign currencies
        # We need to fetch both currency dynamics and calculate cross rates
        from_rates = fetch_rates_to_byn_dynamics(from, start_date, end_date).index_by(&:date)
        to_rates = fetch_rates_to_byn_dynamics(to, start_date, end_date).index_by(&:date)

        rates = []
        start_date.upto(end_date) do |date|
          from_rate = from_rates[date]
          to_rate = to_rates[date]

          if from_rate && to_rate
            # Calculate cross rate: from_currency/to_currency
            cross_rate = from_rate.rate / to_rate.rate
            rates << Rate.new(
              date: date,
              from: from,
              to: to,
              rate: cross_rate
            )
          end
        end

        rates
      end
    end
  end

  private

    def base_url
      "https://api.nbrb.by"
    end

    def client
      @client ||= Faraday.new(url: base_url) do |faraday|
        faraday.request(:retry, {
          max: 2,
          interval: 0.05,
          interval_randomness: 0.5,
          backoff_factor: 2
        })

        faraday.response :raise_error
        faraday.headers["Content-Type"] = "application/json"
      end
    end

    # Fetches the exchange rate for a given currency to BYN (Belarusian Ruble)
    def fetch_rate_to_byn(currency_code, date)
      # First try to get rate using currency code with parammode=2 (ISO 4217 letter code)
      response = client.get("#{base_url}/exrates/rates/#{currency_code.upcase}") do |req|
        req.params["ondate"] = date.strftime("%Y-%m-%d")
        req.params["parammode"] = 2
        req.params["periodicity"] = 0
      end

      parsed = JSON.parse(response.body)

      if parsed.is_a?(Hash) && parsed["Cur_OfficialRate"]
        {
          rate: parsed["Cur_OfficialRate"].to_f / parsed["Cur_Scale"].to_f,
          scale: parsed["Cur_Scale"],
          name: parsed["Cur_Name"]
        }
      else
        raise InvalidExchangeRateError, "No exchange rate found for #{currency_code} on #{date}"
      end
    end

    # Fetches exchange rate dynamics for a given currency to BYN using the dynamics endpoint
    def fetch_rates_to_byn_dynamics(currency_code, start_date, end_date)
      # Get currency info first to obtain Cur_ID and scale
      info_response = client.get("#{base_url}/exrates/rates/#{currency_code.upcase}") do |req|
        req.params["parammode"] = 2
        req.params["periodicity"] = 0
      end

      info_data = JSON.parse(info_response.body)
      currency_id = info_data["Cur_ID"]
      currency_scale = info_data["Cur_Scale"]&.to_f || 1.0

      unless currency_id
        raise InvalidExchangeRateError, "Currency ID not found for #{currency_code}"
      end

      # Now fetch dynamics using the currency ID
      response = client.get("#{base_url}/exrates/rates/dynamics/#{currency_id}") do |req|
        req.params["startdate"] = start_date.strftime("%Y-%m-%d")
        req.params["enddate"] = end_date.strftime("%Y-%m-%d")
      end

      parsed = JSON.parse(response.body)

      if parsed.is_a?(Array)
        parsed.map do |rate_data|
          Rate.new(
            date: Date.parse(rate_data["Date"]),
            from: currency_code.upcase,
            to: "BYN",
            rate: rate_data["Cur_OfficialRate"].to_f / currency_scale
          )
        end
      else
        raise InvalidExchangeRateError, "No exchange rate dynamics found for #{currency_code} between #{start_date} and #{end_date}"
      end
    end
end
