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
      @explicit_wait_time = 4.5
      @wait = Selenium::WebDriver::Wait.new(timeout: @explicit_wait_time) # seconds
      LenovoWarrantyScraper.driver = @driver
      LenovoWarrantyScraper.wait = @wait
      @driver.navigate.to @url
      login_form
      make_claim

    end

    def make_claim
      external_claim_admin_tab
      select_location
      select_service_type
      enter_serial_number
    end

    def login_form
      Element.new("//input[@name='j_username']").send_keys(@secrets['username'])
      Element.new("//input[@name='j_password']").send_keys(@secrets['password'])
      Element.new("//input[@name='uidPasswordLogon']").click
    end

    def external_claim_admin_tab
      Element.new("//a[text()='External Claim Admin']", wait: @explicit_wait_time).click
    end

    def select_location
      sleep(@explicit_wait_time)
      @driver.switch_to.frame @driver.find_element(name: "Desktop Inner Page   ")
      @driver.switch_to.frame @driver.find_element(name: "isolatedWorkArea")
      Element.new("//span[text()='Select Location']/..", wait: @explicit_wait_time).click
      Element.new("//span[text()='Select']/..", wait: @explicit_wait_time).click
    end

    def select_service_type
      Element.new("aaaa.EntitleClaimView.ServiceType", key: :id, wait: @explicit_wait_time).send_keys @settings['service_type']
    end

    def enter_serial_number
      Element.new("aaaa.EntitleClaimView.SerialNo", key: :id, wait: @explicit_wait_time).send_keys @settings['serial_number']
      Element.new("//span[text()='Select Product']/..", wait: @explicit_wait_time).click
      select_latest_warranty_item
    end

    def select_latest_warranty_item
      @driver.switch_to.default_content
      @driver.switch_to.frame @driver.find_element(id: "URLSPW-0")


      rows = @driver.find_elements(xpath: '//*[@id="aaaa.ProductSelectPopupView.ProductListTable-contentTBody"]//tr')

      headings = []
      headings_cells = @driver.find_elements(xpath: "//*[@id=\"aaaa.ProductSelectPopupView.ProductListTable-contentTBody\"]//tr[1]/th/div/span/span")
      headings_cells.each { |cell| headings << cell.text}

      # headings
      # heading row /tr[1]
      # heading text /tr[1]/th[7]/div/span/span
      ## first row
      # row   /tr[3]
      # text /tr[3]/td[7]/span

      rows.each_with_index do |_,index|
        next if index <= 1
        # row = @driver.find_element(xpath: "//*[@id=\"aaaa.ProductSelectPopupView.ProductListTable-contentTBody\"]//tr[#{index}]")
        cells = @driver.find_elements(xpath: "//*[@id=\"aaaa.ProductSelectPopupView.ProductListTable-contentTBody\"]//tr[#{index}]/td/span")

        unless cells.nil?
          puts index
          cells.each { |cell| puts cell.text }
        end
        # t = row.attribute("udat").start_with? "ProductListForTable"

        # if t
        #   cells.each do |cell|
        #     puts cell.text
        #   end
        # end
      end

      print 1



    end

  end
end