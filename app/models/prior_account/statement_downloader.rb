class PriorAccount::StatementDownloader
  LOGIN_PATH = "https://www.prior.by/web/"

  attr_reader :browser, :page, :download_path, :sync
  attr_accessor :start_date, :end_date, :card_name

  def initialize(start_date, end_date, card_name, headless: true, sync: nil)
    @browser = Ferrum::Browser.new(timeout: 20, headless: headless)
    @page = browser.create_page
    @start_date = start_date
    @end_date = end_date
    @card_name = card_name
    @download_path = Dir.mktmpdir("priorbank_statements_")
    @sync = sync
  end

  def call
    sync_update("statement_downloader", "Starting statement download...")
    login
    close_popup
    open_cards
    select_card
    open_statements
    setup_filters
    download_statement
    sleep(1)

    sync_update("statement_downloader", "Statement downloaded successfully!", "success")
    downloaded_file_path
  rescue => e
    page.screenshot(path: Rails.root.join("tmp", "prior_fail-#{Time.now.to_i}.png").to_s, full: true)
    sync_update("statement_downloader", "Failed to download statement: #{e.message}", "error")
    raise e
  ensure
    browser.quit
  end

  def teardown
    FileUtils.rm_rf(download_path) if download_path && Dir.exist?(download_path)
  end

  private

    def sync_update(step, message, status = "in_progress")
      return unless sync

      Rails.logger.info "[PriorAccount::StatementDownloader] Sync update - Step: #{step}, Message: #{message}, Status: #{status}"
      sync.progress_update(step: step, message: message, status: status)
    end

    def login
      sync_update("login", "Logging into Priorbank...")
      page.go_to LOGIN_PATH
      sync_update("login", "Waiting for login form...")
      wait_for('//form[contains(@action, "Login")]', wait: 5, step: 0.5)
      form = page.at_xpath('//form[contains(@action, "Login")]')
      login_input = form.at_xpath('.//input[@name="UserName"]')
      password_input = form.at_xpath('.//input[@name="Password"]')
      submit_button = form.at_xpath('.//button[@type="submit"]')

      login_input.focus.type Setting.priorbank_login
      password_input.focus.type Setting.priorbank_password

      sync_update("login", "Submitting login form...")
      submit_button.click
      sync_update("login", "Waiting for idle...")
      page.network.wait_for_idle

      raise "Failed to login" if page.current_title != "Рабочий стол"

      sync_update("login", "Successfully logged in", "success")
    end

    def close_popup
      sync_update("close_popup", "Closing popup...")

      while popup = page.at_css("div.k-widget.k-window") && popup.visible?
        popup.at_css("span.k-i-close").click
        sync_update("close_popup", "Closed popup")
        sleep(0.1)
      end

      sync_update("close_popup", "No popup found", "success")
    end

    def open_cards
      sync_update("open_cards", "Opening cards page...")

      page.css("span.menu-item-parent").find { |menu| menu.text == "Мои продукты" }.click
      page.css("span.menu-item-parent").find { |menu| menu.text == "Карты" }.click

      sync_update("open_cards", "Waiting for cards table...")
      wait_for("div.bank-cards-list", init: 1, wait: 5, step: 0.5)

      raise "[Priorbank] Failed to open cards" if page.current_title != "Платежные карточки"

      sync_update("open_cards", "Cards page loaded", "success")
    end

    def select_card
      sync_update("select_card", "Start selecting card '#{card_name}'...")
      default_card = page.at_css("div.bank-cards-list tbody tr div.checkbox-cell input:checked")
      default_card.click if default_card

      card_row = page.css("div.bank-cards-list tbody tr").find do |row|
        row.text.include?(card_name)
      end

      raise "[Priorbank] Card '#{card_name}' not found" unless card_row

      checkbox = card_row.at_css("div.checkbox-cell input")
      checkbox.focus
      checkbox.click

      sync_update("select_card", "Card '#{card_name}' selected", "success")
    end

    def open_statements
      sync_update("open_statements", "Opening statements...")
      page.css("ul.nav.nav-pills li.enabled a").find { |link| link.attribute("data-link-action") == "history" }.click

      sync_update("open_statements", "Waiting for filters...")
      filters = wait_for("div.detailedreport-cards-filter", init: 1, wait: 5, step: 0.5)

      raise "[Priorbank] Failed to open statements" unless filters

      sync_update("open_statements", "Statements page loaded", "success")
    end

    def setup_filters
      sync_update("setup_filters", "Setting up date filters...")
      page.css("span.lbl").find { |lbl| lbl.text.strip == "за период" }.click

      sync_update("setup_filters", "Selecting dates #{start_date.strftime('%d.%m.%Y')} - #{end_date.strftime('%d.%m.%Y')}...")
      from = page.xpath("//span[contains(@class, 'k-picker-wrap')]//input")[0]
      to =   page.xpath("//span[contains(@class, 'k-picker-wrap')]//input")[1]

      raise "Can't find datepickers" if !from || !to

      from.focus
      sleep(0.1)
      from.type start_date.strftime("%d%m%Y")
      to.focus
      sleep(0.1)
      to.type end_date.strftime("%d%m%Y")

      sync_update("setup_filters", "Submitting filters...")
      wait_for(".bia-filter .row.actions button.btn.btn-primary", init: 1, wait: 5, step: 0.5)
      page.at_css(".bia-filter .row.actions button.btn.btn-primary").click # First click does not work. To lose focus from datepickers probably
      page.at_css(".bia-filter .row.actions button.btn.btn-primary").click

      sync_update("setup_filters", "Waiting for idle...")
      page.network.wait_for_idle
      wait_for(".bia-context-element-header", wait: 5, step: 0.5)

      card_header = page.at_css(".bia-context-element-header")
      raise "[Priorbank] Card statement not found" unless card_header

      sync_update("setup_filters", "Date filters applied", "success")
    end

    def download_statement
      sync_update("download_statement", "Downloading statement file...")

      page.downloads.set_behavior(save_path: download_path, behavior: :allow)

      link = page.at_css("ul.attachments li:last-child a")
      raise "[Priorbank] Download link not found" unless link

      link.focus
      page.downloads.wait { link.click }

      sync_update("download_statement", "Statement file downloaded", "success")
    end

    def downloaded_file_path
      files = Dir.glob(File.join(download_path, "*.csv"))
      raise "[Priorbank] No CSV file found in download path" if files.empty?

      file_path = files.first
      sync_update("downloaded_file", "Found downloaded file: #{file_path}", "success")

      file_path
    end

    def wait_for(selector, init: nil, wait: 1, step: 0.1, screenshot: false)
      sync_update("wait_for", "Waiting for selector: #{selector}")
      sleep(init) if init
      page.screenshot(path: Rails.root.join("tmp", "prior-wait-#{selector.gsub(/[^a-zA-Z0-9]/, '_')}-#{Time.now.to_i}.png").to_s, full: true) if screenshot
      meth = selector.start_with?("/") ? :at_xpath : :at_css
      until node = page.send(meth, selector) rescue nil
        page.screenshot(path: Rails.root.join("tmp", "prior-wait-#{selector.gsub(/[^a-zA-Z0-9]/, '_')}-#{Time.now.to_i}.png").to_s, full: true) if screenshot
        sync_update("wait_for", "Still waiting for selector: #{selector}")
        (wait -= step) > 0 ? sleep(step) : break
      end
      sync_update("wait_for", "Selector found: #{node}", "success")
      node
    end
end
