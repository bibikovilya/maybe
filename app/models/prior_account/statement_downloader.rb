class PriorAccount::StatementDownloader
  LOGIN_PATH = "https://www.prior.by/web/"

  attr_reader :browser, :page, :download_path
  attr_accessor :start_date, :end_date, :card_name

  def initialize(start_date, end_date, card_name, headless: true)
    @browser = Ferrum::Browser.new(timeout: 20, headless: headless)
    @page = browser.create_page
    @start_date = start_date
    @end_date = end_date
    @card_name = card_name
    @download_path = Dir.mktmpdir("priorbank_statements_")
  end

  def call
    login
    close_popup
    open_cards
    select_card
    open_statements
    setup_filters
    download_statement
    sleep(1)

    downloaded_file_path
  rescue => e
    page.screenshot(path: Rails.root.join("tmp", "prior_fail-#{Time.now.to_i}.png").to_s, full: true)
    Rails.logger.error "[Priorbank] Failed to download statements: #{e.message}"
    raise e
  ensure
    browser.quit
  end

  def teardown
    FileUtils.rm_rf(download_path) if download_path && Dir.exist?(download_path)
  end

  private

    def login
      Rails.logger.info "[Priorbank] Logging in..."
      page.go_to LOGIN_PATH
      Rails.logger.info "[Priorbank] Waiting for login form..."
      wait_for('//form[contains(@action, "Login")]', wait: 5, step: 0.5)
      form = page.at_xpath('//form[contains(@action, "Login")]')
      login_input = form.at_xpath('.//input[@name="UserName"]')
      password_input = form.at_xpath('.//input[@name="Password"]')
      submit_button = form.at_xpath('.//button[@type="submit"]')

      login_input.focus.type Setting.priorbank_login
      password_input.focus.type Setting.priorbank_password

      Rails.logger.info "[Priorbank] Submitting login form..."
      submit_button.click
      Rails.logger.info "[Priorbank] Waiting for idle..."
      page.network.wait_for_idle

      raise "Failed to login" if page.current_title != "Рабочий стол"

      Rails.logger.info "[Priorbank] Successfully logged in"
    end

    def close_popup
      Rails.logger.info "[Priorbank] Closing popup..."

      while popup = page.at_css("div.k-widget.k-window") && popup.visible?
        popup.at_css("span.k-i-close").click

        Rails.logger.info "[Priorbank] Closed popup"

        sleep(0.1)
      end

      Rails.logger.info "[Priorbank] No popup found"
    end

    def open_cards
      Rails.logger.info "[Priorbank] Opening cards page..."

      page.css("span.menu-item-parent").find { |menu| menu.text == "Мои продукты" }.click
      page.css("span.menu-item-parent").find { |menu| menu.text == "Карты" }.click

      Rails.logger.info "[Priorbank] Waiting for cards table..."
      wait_for("div.bank-cards-list", init: 1, wait: 5, step: 0.5)

      raise "[Priorbank] Failed to open cards" if page.current_title != "Платежные карточки"

      Rails.logger.info "[Priorbank] Successfully opened cards page"
    end

    def select_card
      Rails.logger.info "[Priorbank] Unselecting default card..."
      default_card = page.at_css("div.bank-cards-list tbody tr div.checkbox-cell input:checked")
      default_card.click if default_card

      Rails.logger.info "[Priorbank] Selecting card '#{card_name}'..."
      card_row = page.css("div.bank-cards-list tbody tr").find do |row|
        row.text.include?(card_name)
      end

      raise "[Priorbank] Card '#{card_name}' not found" unless card_row

      checkbox = card_row.at_css("div.checkbox-cell input")
      checkbox.focus
      checkbox.click

      Rails.logger.info "[Priorbank] Successfully selected card '#{card_name}'"
    end

    def open_statements
      Rails.logger.info "[Priorbank] Opening statements..."
      page.css("ul.nav.nav-pills li.enabled a").find { |link| link.attribute("data-link-action") == "history" }.click

      Rails.logger.info "[Priorbank] Waiting for filters..."
      filters = wait_for("div.detailedreport-cards-filter", init: 1, wait: 5, step: 0.5)

      raise "[Priorbank] Failed to open statements" unless filters

      Rails.logger.info "[Priorbank] Successfully opened statements"
    end

    def setup_filters
      Rails.logger.info "[Priorbank] Setting up filters..."
      page.css("span.lbl").find { |lbl| lbl.text.strip == "за период" }.click

      Rails.logger.info "[Priorbank] Selecting dates..."
      from = page.xpath("//span[contains(@class, 'k-picker-wrap')]//input")[0]
      to =   page.xpath("//span[contains(@class, 'k-picker-wrap')]//input")[1]

      raise "Can't find datepickers" if !from || !to

      from.focus
      sleep(0.1)
      from.type start_date.strftime("%d%m%Y")
      to.focus
      sleep(0.1)
      to.type end_date.strftime("%d%m%Y")

      Rails.logger.info "[Priorbank] Submitting filters..."
      wait_for(".bia-filter .row.actions button.btn.btn-primary", init: 1, wait: 5, step: 0.5)
      page.at_css(".bia-filter .row.actions button.btn.btn-primary").click # First click does not work. To lose focus from datepickers probably
      page.at_css(".bia-filter .row.actions button.btn.btn-primary").click

      Rails.logger.info "[Priorbank] Waiting for idle..."
      page.network.wait_for_idle
      wait_for(".bia-context-element-header", wait: 5, step: 0.5)

      card_header = page.at_css(".bia-context-element-header")
      raise "[Priorbank] Card statement not found" unless card_header

      Rails.logger.info "[Priorbank] Successfully set up filters"
    end

    def download_statement
      Rails.logger.info "[Priorbank] Downloading statement for '#{card_name}'..."

      page.downloads.set_behavior(save_path: download_path, behavior: :allow)

      link = page.at_css("ul.attachments li:last-child a")
      raise "[Priorbank] Download link not found" unless link

      link.focus
      page.downloads.wait { link.click }

      Rails.logger.info "[Priorbank] Successfully downloaded statement"
    end

    def downloaded_file_path
      files = Dir.glob(File.join(download_path, "*.csv"))
      raise "[Priorbank] No CSV file found in download path" if files.empty?

      file_path = files.first
      Rails.logger.info "[Priorbank] Found downloaded file: #{file_path}"

      file_path
    end

    def wait_for(selector, init: nil, wait: 1, step: 0.1, screenshot: false)
      Rails.logger.info "[Priorbank] Waiting for selector: #{selector}"
      sleep(init) if init
      page.screenshot(path: Rails.root.join("tmp", "prior-wait-#{selector.gsub(/[^a-zA-Z0-9]/, '_')}-#{Time.now.to_i}.png").to_s, full: true) if screenshot
      meth = selector.start_with?("/") ? :at_xpath : :at_css
      until node = page.send(meth, selector) rescue nil
        page.screenshot(path: Rails.root.join("tmp", "prior-wait-#{selector.gsub(/[^a-zA-Z0-9]/, '_')}-#{Time.now.to_i}.png").to_s, full: true) if screenshot
        Rails.logger.info "[Priorbank] Still waiting for selector: #{selector}"
        (wait -= step) > 0 ? sleep(step) : break
      end
      node
    end
end
