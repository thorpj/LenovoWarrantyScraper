module LenovoWarrantyScraper
  class Scraper
    def initialize
      @url = "https://csp.lenovo.com/irj/portal"
      @secrets = YAML.load_file(File.join(File.dirname(__dir__), '../config/secrets.yaml'))
      @settings = YAML.load_file(File.join(File.dirname(__dir__), '../config/settings.yaml'))

      if @settings['headless']
        options = Selenium::WebDriver::Firefox::Options.new(args: ['-headless'])
        @driver = Selenium::WebDriver.for(:firefox, options: options)
      else
        @driver = Selenium::WebDriver.for(:firefox)
      end

      @driver.manage.window.resize_to(1000,800)
      @driver.manage.timeouts.implicit_wait = 10 # seconds
      @wait = Selenium::WebDriver::Wait.new(timeout: 10) # seconds
      LenovoWarrantyScraper.driver = @driver
      LenovoWarrantyScraper.wait = @wait
      @driver.navigate.to @url
      login_form
      external_claim_admin_tab
    end

    def login_form
      Element.new("//input[@name='j_username']").send_keys(@secrets['username'])
      Element.new("//input[@name='j_password']").send_keys(@secrets['password'])
      Element.new("//input[@name='uidPasswordLogon']").click
    end

    def external_claim_admin_tab
      Element.new("//a[text()='External Claim Admin']", wait: 3).click
    end

    def select_location
      Element.new("//span[text()='Select Location']".click)
      Element.new("//span[text()='Select']").click
    end

    def select_service_type(service_type)
      Element.new()
    end
  end
end