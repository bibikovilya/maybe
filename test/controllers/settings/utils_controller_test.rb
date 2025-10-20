require "test_helper"

class Settings::UtilsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:family_admin)
    sign_in @user
  end

  test "should get show" do
    get settings_utils_path
    assert_response :success
  end

  test "fix_encoding returns zip file when files are provided" do
    zip_path = Rails.root.join("tmp", "test_fixed.zip")
    zip_data = "fake zip data"

    fixer = mock("fixer")
    fixer.expects(:call).returns(zip_path)
    fixer.expects(:cleanup)

    Utils::CsvEncodingFixer.expects(:new).with([ "file1.csv", "file2.csv" ]).returns(fixer)
    File.expects(:binread).with(zip_path).returns(zip_data)

    post fix_encoding_settings_utils_path, params: { csv_files: [ "file1.csv", "file2.csv" ] }

    assert_response :success
    assert_equal "application/zip", response.content_type
    assert_match(/fixed_encoding_\d+\.zip/, response.headers["Content-Disposition"])
  end

  test "fix_encoding redirects with alert when no files selected" do
    fixer = mock("fixer")
    fixer.expects(:call).raises(Utils::CsvEncodingFixer::NoFilesError)

    Utils::CsvEncodingFixer.expects(:new).returns(fixer)

    post fix_encoding_settings_utils_path, params: { csv_files: [ "" ] }

    assert_redirected_to settings_utils_path
    assert_equal I18n.t("settings.utils.fix_encoding.no_files_selected"), flash[:alert]
  end

  test "fix_encoding redirects with error message when exception occurs" do
    error_message = "Something went wrong"
    fixer = mock("fixer")
    fixer.expects(:call).raises(StandardError.new(error_message))

    Utils::CsvEncodingFixer.expects(:new).returns(fixer)
    Rails.logger.expects(:error).with(regexp_matches(/Error fixing encoding: #{error_message}/))

    post fix_encoding_settings_utils_path, params: { csv_files: [ "file1.csv" ] }

    assert_redirected_to settings_utils_path
    assert_equal I18n.t("settings.utils.fix_encoding.error_processing", error: error_message), flash[:alert]
  end
end
