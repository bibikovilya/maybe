Rails.application.configure do
  if ENV["PRIORBANK_LOGIN"].present? && ENV["PRIORBANK_PASSWORD"].present?
    config.prior = Struct.new(:login, :password).new(
      ENV.fetch("PRIORBANK_LOGIN") { Setting.priorbank_login },
      ENV.fetch("PRIORBANK_PASSWORD") { Setting.priorbank_password }
    )
  end
end
