module LenovoWarrantyScraper
  class Scraper
    def initialize
      @secrets = YAML.load_file(File.join(File.dirname(__dir__), '../config/secrets.yaml'))
      @settings = YAML.load_file(File.join(File.dirname(__dir__), '../config/settings.yaml'))
      @url = @settings['url']

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
    end

    def switch_to_external_claim_admin_iframe
      sleep(@explicit_wait_time)
      @driver.switch_to.default_content
      @driver.switch_to.frame @driver.find_element(id: "ivuFrm_page0ivu3")
      @driver.switch_to.frame @driver.find_element(id: "isolatedWorkArea")
    end

    def switch_to_popup_iframe
      sleep(@explicit_wait_time)
      @driver.switch_to.default_content
      @driver.switch_to.frame @driver.find_element(id: "URLSPW-0")
    end

    def make_claim(serial_number)
      external_claim_admin_tab
      select_location
      select_service_type
      enter_serial_number(serial_number)
      select_service_date
      select_technician
      select_service_delivery_type
      select_external_claim_admin_continue
      select_customer
      enter_ticket_number
      enter_failure_description
      enter_comments
      # submit_claim
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
      switch_to_external_claim_admin_iframe
      Element.new("//span[text()='Select Location']/..", wait: @explicit_wait_time).click
      Element.new("//span[text()='Select']/..", wait: @explicit_wait_time).click
    end

    def select_service_type
      Element.new("aaaa.EntitleClaimView.ServiceType", key: :id, wait: @explicit_wait_time).send_keys @settings['service_type']
    end

    def enter_serial_number(serial_number)
      Element.new("aaaa.EntitleClaimView.SerialNo", key: :id, wait: @explicit_wait_time).send_keys serial_number
      Element.new("//span[text()='Select Product']/..", wait: @explicit_wait_time).click
      select_latest_warranty_item
    end

    def select_latest_warranty_item
      switch_to_popup_iframe


      sleep(@explicit_wait_time)
      headings = []
      headings_cells = @driver.find_elements(xpath: "//*[@id=\"aaaa.ProductSelectPopupView.ProductListTable-contentTBody\"]//tr[1]/th/div/span/span")
      headings_cells.each { |cell| headings << cell.text}

      ## headings
      # heading row $table_path/tr[1]
      # heading text $table_path/tr[1]/th[7]/div/span/span
      ## first row
      # row   $table_path/tr[3]
      # text $table_path/tr[3]/td[7]/span

      table = []
      rows = @driver.find_elements(xpath: '//*[@id="aaaa.ProductSelectPopupView.ProductListTable-contentTBody"]//tr')

      rows.each_with_index do |_,index|
        next if index <= 1
        cells = @driver.find_elements(xpath: "//*[@id=\"aaaa.ProductSelectPopupView.ProductListTable-contentTBody\"]//tr[#{index}]/td/span")

        if table.length > 0 && cells.empty?
          break
        elsif cells.empty?
          next
        else
          table_entry = {}
          cells.zip(headings).each { |cell, heading|
            table_entry[heading] = cell.text
            table_entry['index'] = index
          }
          table << table_entry
        end
      end

      latest_warranty_item = table.max_by { |k,v| k['End Date']}
      index = (latest_warranty_item['index']).to_s
      Element.new("//*[@id=\"aaaa.ProductSelectPopupView.ProductListTable-contentTBody\"]//tr[#{index}]/td[7]/span", key: :xpath).click
      switch_to_external_claim_admin_iframe
    end

    def select_service_date
      date = Time.now.strftime("%d.%m.%Y")
      if @settings.key? "service_date"
        date = @settings['service_date']
      end
      Element.new("aaaa.EntitleClaimView.ServiceDate", key: :id, wait: @explicit_wait_time).send_keys date
    end

    def select_technician
      Element.new("aaaa.EntitleClaimView.Technician",
                  key: :id, wait: @explicit_wait_time).send_keys @secrets['technician_code']
    end

    def select_service_delivery_type
      Element.new("aaaa.EntitleClaimView.ServiceDeliveryType", key: :id, wait: @explicit_wait_time).send_keys @settings['service_delivery_type']
    end

    def select_external_claim_admin_continue
      Element.new("aaaa.EntitleClaimView.Continue", key: :id, wait: @explicit_wait_time).click
      Element.new("aaaa.EntitlementResultsView.Continue", key: :id, wait: @explicit_wait_time).click
    end

    def select_customer
      Element.new("aaaa.ClaimCompleAndSubmitView.SelectCusButton", key: :id, wait: @explicit_wait_time).click
      switch_to_popup_iframe

      sleep(@explicit_wait_time)
      headings = []
      headings_cells = @driver.find_elements(xpath: "//*[@id=\"aaaa.CustomerSelectPopupView.CustomerTable-contentTBody\"]//tr[1]/td/div/span/span")
      headings_cells.each { |cell| headings << cell.text}

      search_field_index = (headings.index @settings['customer_search_field']) + 2 # One for table index being one based instead of zero based. Another one because the first column is a blank cell

      search_field = @driver.find_element(xpath: "//*[@id=\"aaaa.CustomerSelectPopupView.CustomerTable-contentTBody\"]//tr[2]/td[#{search_field_index}]/table/tbody/tr/td/input")
      search_field.send_keys @secrets['company'], :return

      Element.new("aaaa.CustomerSelectPopupView.SelectButton", key: :id, wait: @explicit_wait_time).click
      switch_to_external_claim_admin_iframe
    end

    def enter_ticket_number
      Element.new("aaaa.ClaimCompleAndSubmitView.BPClaimRefID", key: :id, wait: @explicit_wait_time).send_keys @secrets['ticket_number']
    end

    def enter_failure_description
      Element.new("aaaa.ClaimCompleAndSubmitView.FailDescTextEdit", key: :id, wait: @explicit_wait_time).send_keys @secrets['failure_description']
    end

    def enter_comments
      Element.new("aaaa.ClaimCompleAndSubmitView.TextEdit1", key: :id, wait: @explicit_wait_time).send_keys @secrets['comments']
    end

    def submit_claim
      Element.new("aaaa.ClaimCompleAndSubmitView.Submit", key: :id, wait: @explicit_wait_time).click
    end
  end
end