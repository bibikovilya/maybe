class Settings::UtilsController < ApplicationController
  layout "settings"

  def show
  end

  def fix_encoding
    fixer = Utils::CsvEncodingFixer.new(params[:csv_files])
    zip_path = fixer.call
    zip_data = File.binread(zip_path)
    fixer.cleanup

    send_data zip_data,
              filename: "fixed_encoding_#{Time.current.to_i}.zip",
              type: "application/zip",
              disposition: "attachment"
  rescue Utils::CsvEncodingFixer::NoFilesError
    redirect_to settings_utils_path, alert: t(".no_files_selected")
  rescue => e
    Rails.logger.error "Error fixing encoding: #{e.message}\n#{e.backtrace.join("\n")}"
    redirect_to settings_utils_path, alert: t(".error_processing", error: e.message)
  end
end
