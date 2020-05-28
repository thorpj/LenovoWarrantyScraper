require 'time'


module LenovoWarrantyScraper
  class Scraper
    def initialize(secrets, settings)
      @secrets = secrets
      @settings = settings
      @url = @settings[:url]

      if @settings[:headless]
        options = Selenium::WebDriver::Firefox::Options.new(args: ['-headless'])
        @driver = Selenium::WebDriver.for(:firefox, options: options)
      else
        @driver = Selenium::WebDriver.for(:firefox)
      end

      @driver.manage.window.resize_to(1000,800)
      @driver.manage.timeouts.implicit_wait = 10 # seconds
      @explicit_wait_time = @settings[:explicit_wait_time]
      @wait = Selenium::WebDriver::Wait.new(timeout: @explicit_wait_time) # seconds
      LenovoWarrantyScraper.driver = @driver
      LenovoWarrantyScraper.wait = @wait

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

    def make_adp_clw_claim(serial_number, parts, ticket_number, failure_description, comments, customer, service_type, authorization_code=nil)
      puts "Processing: #{{serial_number: serial_number, parts: parts, ticket_number: ticket_number, failure_description: failure_description, comments: comments}}"
      navigate_to_url
      login_form
      external_claim_admin_tab
      select_location
      select_service_type(service_type)
      if service_type == 'ADP'
        if authorization_code.present?
          enter_authorization_code(authorization_code)
        else
          service_type = 'CLW'
          select_service_type(service_type)
        end
      end
      enter_serial_number(serial_number)
      select_service_date
      select_technician
      select_service_delivery_type
      select_external_claim_admin_continue
      select_parts(parts)
      select_external_claim_admin_confirm_continune
      select_customer(customer)
      select_ship_to_location
      enter_ticket_number(ticket_number)
      enter_failure_description(failure_description)
      enter_comments(comments)
      submit_claim if @settings[:submit_claim]
      warranty_reference = read_warranty_reference
      puts warranty_reference
      quit
      warranty_reference
    end

    def quit
      @driver.quit
      $logger.debug "Closing webdriver"
    end

    def close
      @driver.close
      $logger.debug "Closing window"
    end

    def navigate_to_url
      @driver.navigate.to @url
    end

    def login_form
      Element.new("//input[@name='j_username']").send_keys(@secrets[:username])
      Element.new("//input[@name='j_password']").send_keys(@secrets[:password])
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

    def select_service_type(service_type)
      case service_type
      when "CLW"
        service_type = "Customer Ltd Warranty"
      when "ADP"
        service_type = "Accidental Damage Claim"
      when "DOA"
        service_type = "DOA Claim"
      when "LOC"
        service_type = "Labour Only Claim"
      end
      Element.new("aaaa.EntitleClaimView.ServiceType", key: :id, wait: @explicit_wait_time).send_keys service_type
    end

    def enter_serial_number(serial_number)
      Element.new("aaaa.EntitleClaimView.SerialNo", key: :id, wait: @explicit_wait_time).send_keys serial_number
      Element.new("//span[text()='Select Product']/..", wait: @explicit_wait_time).click
      select_latest_warranty_item
    end

    def read_errors
      errors = []
      sleep(@explicit_wait_time)
      rows = @driver.find_elements(xpath: '//*[@id="aaaa.EntitleClaimView.MessageArea-contentTBody"]//tr')

      rows.each_with_index do |_,index|
        cells = @driver.find_elements(xpath: "//*[@id=\"aaaa.EntitleClaimView.MessageArea-contentTBody\"]//tr[#{index}]/td/div/table/tbody/tr/td/span")
        unless cells.empty?
          errors << cells.first.text
        end
      end

      begin
        errors << Element.new("aaaa.EntitleClaimView.MessageArea-txt", key: :id, wait: @explicit_wait_time).value
      rescue
      end
      errors
    end

    def check_errors
      errors = read_errors

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
      latest_warranty_item = table.max_by do |warranty|
        end_date = warranty['End Date']
        Date.parse(end_date) unless end_date.nil?
      end
      in_warranty = date_is_not_past(latest_warranty_item['End Date'])
      unless in_warranty
        raise LenovoWarrantyScraper::OutOfWarrantyError
      end
      index = (latest_warranty_item['index']).to_s
      Element.new("//*[@id=\"aaaa.ProductSelectPopupView.ProductListTable-contentTBody\"]//tr[#{index}]/td[7]/span", key: :xpath).click
      switch_to_external_claim_admin_iframe
    end

    def select_service_date
      date = Time.now.strftime(@settings[:date_format])
      if @settings.key? "service_date"
        date = @settings[:service_date]
      end
      Element.new("aaaa.EntitleClaimView.ServiceDate", key: :id, wait: @explicit_wait_time).send_keys date
    end

    def select_technician
      Element.new("aaaa.EntitleClaimView.Technician",
                  key: :id, wait: @explicit_wait_time).send_keys @secrets[:technician_code]
    end

    def enter_authorization_code(code)
      Element.new("aaaa.EntitleClaimView.RMANumber", key: :id, wait: @explicit_wait_time).send_keys code
    end

    def select_service_delivery_type(service_delivery_type = @settings[:service_delivery_type])
      Element.new("aaaa.EntitleClaimView.ServiceDeliveryType", key: :id, wait: @explicit_wait_time).send_keys service_delivery_type
    end

    # Continue button on first page of claim
    def select_external_claim_admin_continue
      Element.new("aaaa.EntitleClaimView.Continue", key: :id, wait: @explicit_wait_time).click
      sleep(@explicit_wait_time)

      # Handle incorrect Service Delivery Type
      errors = nil
      begin
        errors = read_errors
        if errors.include? @settings[:errors][:service_delivery_type_not_authorized]
          select_service_delivery_type("Carry-in")
        end
        sleep(@explicit_wait_time)
        Element.new("aaaa.EntitleClaimView.Continue", key: :id, wait: @explicit_wait_time).click
        sleep(@explicit_wait_time)
      rescue
      end


      switch_to_popup_iframe
      # Handle existing claim within 30 days warning
      begin
        continue_button = Element.new("//table[@class=\"urPWButtonTable\"]/tbody/tr/td[1]/a", key: :xpath)
        continue_button.click
      rescue
      end
      switch_to_external_claim_admin_iframe
    end

    def select_parts(parts)
      headings = []
      headings_cells = @driver.find_elements(xpath: "//*[@id=\"aaaa.EntitlementResultsView.Table_-contentTBody\"]//tr[1]/th/table/tbody/tr/td/div/span")
      headings_cells.each { |cell| headings << cell.text }

      search_field_index = (headings.index @settings[:part_search_field]) + 2 # One for table index being one based instead of zero based. Another one because the first column is a blank cell

      parts.each do |part|
        sleep(@explicit_wait_time)
        search_field = @driver.find_element(xpath: "//*[@id=\"aaaa.EntitlementResultsView.Table_-contentTBody\"]//tr[2]/td[#{search_field_index}]/table/tbody/tr/td/input")
        search_field.send_keys part, :return
        sleep(@explicit_wait_time)
        part_field = @driver.find_element(xpath: "//*[@id=\"aaaa.EntitlementResultsView.Table_-contentTBody\"]/tr[3]/td[#{search_field_index}]/span")
        sleep(@explicit_wait_time)
        part_field.click
        sleep(@explicit_wait_time)
        search_field = @driver.find_element(xpath: "//*[@id=\"aaaa.EntitlementResultsView.Table_-contentTBody\"]//tr[2]/td[#{search_field_index}]/table/tbody/tr/td/input")
        sleep(@explicit_wait_time)
        search_field.clear
      end

    rescue => error
      raise PartNotFoundError.new("#{parts} #{error.message}")
    end

    # Continue button on parts select page
    def select_external_claim_admin_confirm_continune
      Element.new("aaaa.EntitlementResultsView.Continue", key: :id, wait: @explicit_wait_time).click
    end

    def select_customer(customer)
      Element.new("aaaa.ClaimCompleAndSubmitView.SelectCusButton", key: :id, wait: @explicit_wait_time).click
      switch_to_popup_iframe

      sleep(@explicit_wait_time)
      headings = []
      headings_cells = @driver.find_elements(xpath: "//*[@id=\"aaaa.CustomerSelectPopupView.CustomerTable-contentTBody\"]//tr[1]/td/div/span/span")
      headings_cells.each { |cell| headings << cell.text }

      search_field_index = (headings.index @settings[:customer_search_field]) + 2 # One for table index being one based instead of zero based. Another one because the first column is a blank cell

      search_field = @driver.find_element(xpath: "//*[@id=\"aaaa.CustomerSelectPopupView.CustomerTable-contentTBody\"]//tr[2]/td[#{search_field_index}]/table/tbody/tr/td/input")
      search_field.send_keys customer, :return

      Element.new("aaaa.CustomerSelectPopupView.SelectButton", key: :id, wait: @explicit_wait_time).click
      switch_to_external_claim_admin_iframe
    rescue => error
      raise AccountNotFoundError.new("#{customer} #{error.message}")
    end

    def select_ship_to_location
      Element.new("aaaa.ClaimCompleAndSubmitView.DropDownByKey4", key: :id, wait: @explicit_wait_time).send_keys "Dealer"
    end


    def enter_ticket_number(ticket_number = nil)
      ticket_number = @secrets[:ticket_number] if ticket_number.nil?
      Element.new("aaaa.ClaimCompleAndSubmitView.BPClaimRefID", key: :id, wait: @explicit_wait_time).send_keys ticket_number
    end

    def enter_failure_description(failure_description = nil)
      failure_description = @secrets[:failure_description] if failure_description.nil?
      Element.new("aaaa.ClaimCompleAndSubmitView.FailDescTextEdit", key: :id, wait: @explicit_wait_time).send_keys failure_description
    end

    def enter_comments(comments = nil)
      comments = @secrets[:comments] if comments.nil?
      Element.new("aaaa.ClaimCompleAndSubmitView.TextEdit1", key: :id, wait: @explicit_wait_time).send_keys comments
    end

    def submit_claim
      Element.new("aaaa.ClaimCompleAndSubmitView.Submit", key: :id, wait: @explicit_wait_time).click
      switch_to_popup_iframe
      continue_button = Element.new("//table[@class=\"urPWButtonTable\"]/tbody/tr/td[1]/a", key: :xpath, wait: @explicit_wait_time)
      continue_button.click
      switch_to_external_claim_admin_iframe
    end

    def read_warranty_reference
      Element.new("//*[@id='aaaa.ClaimConfirmationView.ClaimNumber']", key: :xpath, wait: @explicit_wait_time).read_text
    end

    def date_is_not_past(date)
      date = Time.strptime(date, @settings[:date_format])
      date >= Time.now
    end
  end



  class ApiError < StandardError
    attr_reader :message
    def initialize(message)
      @message = message
    end
  end

  class OutOfWarrantyError < StandardError
  end

  class ExceedsServiceDateThresholdError < StandardError
  end

  class AccountNotFoundError < StandardError
  end

  class PartNotFoundError < StandardError
  end
end