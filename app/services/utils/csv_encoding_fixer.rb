# frozen_string_literal: true

require "zip"
require "csv"

module Utils
  class CsvEncodingFixer
    class NoFilesError < StandardError; end

    def initialize(uploaded_files)
      @uploaded_files = uploaded_files.reject(&:blank?)
      @temp_dir = nil
    end

    def call
      setup_temp_directory
      create_zip_with_converted_files
      zip_path
    end

    def cleanup
      if temp_dir && Dir.exist?(temp_dir)
        FileUtils.rm_rf(temp_dir)
      end
    end

    private

      attr_reader :uploaded_files, :temp_dir, :zip_path

      def setup_temp_directory
        raise NoFilesError if uploaded_files.blank?

        @temp_dir = Dir.mktmpdir
        @zip_path = File.join(temp_dir, "fixed_files.zip")
      end

      def create_zip_with_converted_files
        Zip::File.open(zip_path, Zip::File::CREATE) do |zipfile|
          uploaded_files.each do |uploaded_file|
            zipfile.get_output_stream(uploaded_file.original_filename) do |stream|
              stream.write(convert(uploaded_file))
            end
          end
        end
      end

      def convert(uploaded_file)
        self.class.convert_file(uploaded_file.tempfile.path)
      end

      class << self
        def convert_file(file_path)
          converted_csv = StringIO.new

          CSV.open(converted_csv, "w") do |csv|
            CSV.foreach(
              file_path,
              encoding: Encoding::Windows_1251,
              liberal_parsing: true,
              col_sep: ";"
            ) do |row|
              csv << row
            end
          end

          converted_csv.string
        end
      end
  end
end
