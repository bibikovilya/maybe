require "test_helper"

module Utils
  class CsvEncodingFixerTest < ActiveSupport::TestCase
    setup do
      @temp_files = []
    end

    teardown do
      @temp_files.each do |file|
        file.close
        file.unlink
      end
    end

    test "raises NoFilesError when initialized with empty array" do
      fixer = CsvEncodingFixer.new([])

      assert_raises(CsvEncodingFixer::NoFilesError) do
        fixer.call
      end
    end

    test "raises NoFilesError when initialized with empty string values" do
      fixer = CsvEncodingFixer.new([ "", "" ])

      assert_raises(CsvEncodingFixer::NoFilesError) do
        fixer.call
      end
    end

    test "creates zip file with converted CSV" do
      uploaded_file = create_test_csv_file("test.csv", "Name;Age\nJohn;30")
      fixer = CsvEncodingFixer.new([ uploaded_file ])

      zip_path = fixer.call

      assert File.exist?(zip_path)
      assert_equal "application/zip", Marcel::MimeType.for(Pathname.new(zip_path))

      fixer.cleanup
      assert_not File.exist?(zip_path)
    end

    test "converts multiple CSV files into single zip" do
      file1 = create_test_csv_file("file1.csv", "Name;Age\nJohn;30")
      file2 = create_test_csv_file("file2.csv", "City;Country\nParis;France")
      fixer = CsvEncodingFixer.new([ file1, file2 ])

      zip_path = fixer.call

      Zip::File.open(zip_path) do |zip_file|
        assert_equal 2, zip_file.count
        assert zip_file.find_entry("file1.csv")
        assert zip_file.find_entry("file2.csv")
      end

      fixer.cleanup
    end

    test "converts Windows-1251 encoded CSV correctly" do
      # Create proper Windows-1251 encoded content
      utf8_content = "Дата транзакции;Операция;\n18.10.2025 09:07:01;Retail BLR MINSK. ;"
      windows1251_content = utf8_content.encode("Windows-1251")
      uploaded_file = create_test_csv_file("russian.csv", windows1251_content, binary: true)
      fixer = CsvEncodingFixer.new([ uploaded_file ])

      zip_path = fixer.call

      Zip::File.open(zip_path) do |zip_file|
        entry = zip_file.find_entry("russian.csv")
        csv_content = entry.get_input_stream.read.force_encoding(Encoding::UTF_8)

        assert_equal Encoding::UTF_8, csv_content.encoding
        assert csv_content.valid_encoding?, "Content should be valid UTF-8"
        assert csv_content.include?("Дата транзакции")
      end

      fixer.cleanup
    end

    test "cleanup removes temporary directory" do
      uploaded_file = create_test_csv_file("test.csv", "Name;Age\nJohn;30")
      fixer = CsvEncodingFixer.new([ uploaded_file ])

      zip_path = fixer.call
      temp_dir = File.dirname(zip_path)

      assert Dir.exist?(temp_dir)

      fixer.cleanup

      assert_not Dir.exist?(temp_dir)
    end

    test "cleanup is safe to call when directory doesn't exist" do
      uploaded_file = create_test_csv_file("test.csv", "Name;Age\nJohn;30")
      fixer = CsvEncodingFixer.new([ uploaded_file ])

      fixer.call
      fixer.cleanup

      assert_nothing_raised do
        fixer.cleanup
      end
    end

    test "filters out blank uploaded files" do
      file1 = create_test_csv_file("test1.csv", "Name;Age\nJohn;30")
      file2 = create_test_csv_file("test2.csv", "City;Country\nParis;France")
      fixer = CsvEncodingFixer.new([ file1, nil, "", file2 ])

      zip_path = fixer.call

      Zip::File.open(zip_path) do |zip_file|
        assert_equal 2, zip_file.count
      end

      fixer.cleanup
    end

    test "preserves original filenames in zip" do
      file1 = create_test_csv_file("custom_name.csv", "Data\n123")
      file2 = create_test_csv_file("another_file.csv", "Info\nTest")
      fixer = CsvEncodingFixer.new([ file1, file2 ])

      zip_path = fixer.call

      Zip::File.open(zip_path) do |zip_file|
        assert zip_file.find_entry("custom_name.csv")
        assert zip_file.find_entry("another_file.csv")
      end

      fixer.cleanup
    end

    private

      def create_test_csv_file(filename, content, binary: false)
        tempfile = Tempfile.new([ filename, ".csv" ])
        if binary
          tempfile.binmode
          tempfile.write(content)
        else
          tempfile.write(content)
        end
        tempfile.rewind
        @temp_files << tempfile

        # Mock ActionDispatch::Http::UploadedFile
        uploaded_file = OpenStruct.new(
          tempfile: tempfile,
          original_filename: filename
        )

        uploaded_file
      end
  end
end
