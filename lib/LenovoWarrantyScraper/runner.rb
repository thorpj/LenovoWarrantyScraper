module LenovoWarrantyScraper


  class Runner
    def initialize(secrets = nil, settings = nil)
      @scraper = nil
      @settings = settings
      @secrets = secrets

      if @secrets.nil? && @settings.nil?
        @settings = LenovoWarrantyScraper.load_settings
        @secrets = LenovoWarrantyScraper.load_secrets
        @state_manager = LenovoWarrantyScraper::StateManager.new(@secrets, @settings)
      end
      @serial_number = nil
    end

    def single_claim(serial_number:, customer:, ticket_number:, parts:, failure_description:, comments:, service_type: 'CLW', authorization_code: nil, doa_warranty_reference: nil)
      begin
        @scraper = LenovoWarrantyScraper::Scraper.new(@secrets, @settings)
        warranty_reference = @scraper.make_adp_clw_claim(serial_number: serial_number, parts: parts, ticket_number: ticket_number, failure_description: failure_description, comments: comments, customer: customer, service_type: service_type, authorization_code: authorization_code, doa_warranty_reference: doa_warranty_reference)
        warranty_reference
      rescue Selenium::WebDriver::Error::NoSuchElementError, Selenium::WebDriver::Error::StaleElementReferenceError, Selenium::WebDriver::Error::UnknownError, Selenium::WebDriver::Error::ExpectedError, Selenium::WebDriver::Error::NoSuchWindowError, Selenium::WebDriver::Error::InvalidSessionIdError, StandardError => e
        $logger.debug e.backtrace
        @scraper.quit if @scraper&.respond_to? :quit
        raise ApiError.new "Claim Failed: #{e.inspect} #{e.message} #{{serial_number: serial_number, parts: parts, ticket_number: ticket_number, failure_description: failure_description, comments: comments, account: customer}}\nBacktrace\n#{e.backtrace.join("\n")}"
      end
    end

    def run
      @state_manager.input.each do |serial_number|
        serial_number = serial_number[0]
        $logger.info "Processing serial number #{serial_number}"
        @serial_number = serial_number
        submit_claim
      end
      @state_manager.save_state_file
    end

    def failure_sleep(attempts)
      time = @settings[:failure_sleep_times][attempts]
      sleep(time)
    end

    def parts_to_array(parts)
      parts.split(" ")
    end

    def submit_claim
      attempts = 0
      @state_manager.add_new(@serial_number)
      status = @state_manager.get_attribute(@serial_number, 'status')
      ticket_number = @state_manager.get_attribute(@serial_number, 'ticket_number')
      failure_description = @state_manager.get_attribute(@serial_number, 'failure_description')
      comments = @state_manager.get_attribute(@serial_number, 'comments')
      parts = parts_to_array((@state_manager.get_attribute(@serial_number, 'parts')))
      customer = @state_manager.get_attribute(@serial_number, 'customer')
      service_type = @state_manager.get_attribute(@serial_number, 'service_type')
      warranty_reference = @state_manager.get_attribute(@serial_number, 'warranty_reference')
      if status != 'submitted' || warranty_reference.nil?
        $logger.debug "Lodging claim"
        while attempts < @settings[:max_attempts]
          begin
            @scraper = LenovoWarrantyScraper::Scraper.new(@secrets, @settings)
            warranty_reference = @scraper.make_adp_clw_claim(serial_number: @serial_number, parts: parts, ticket_number: ticket_number, failure_description: failure_description, comments: comments, customer: customer, service_type: service_type, authorization_code: nil, doa_warranty_reference: nil)
            unless warranty_reference.nil? || warranty_reference == ''
              update_status(:submitted)
              update_warranty_reference(warranty_reference)
              $logger.debug "Claim successful #{@serial_number} #{warranty_reference}"
              @state_manager.save_and_reload_state_file
              attempts += 1
              break
            end
          rescue Selenium::WebDriver::Error::NoSuchElementError, Selenium::WebDriver::Error::ObsoleteElementError, Selenium::WebDriver::Error::UnhandledError, Selenium::WebDriver::Error::ExpectedError, Selenium::WebDriver::Error::NoSuchWindowError, Selenium::WebDriver::Error::InvalidSessionIdError => e
            $logger.debug e
            $logger.debug "Failed to submit claim, retrying"
            attempts += 1
            failure_sleep(attempts)
          end
          break
        end
        if attempts >= 4
          update_status(:failed)
          $logger.debug "Failed to submit claim"
        end
      else
        $logger.debug "Claim already submitted"
      end
    end

    def update_status(status)
      @state_manager.update_attribute(@serial_number, 'status', status)
    end

    def update_warranty_reference(warranty_reference)
      @state_manager.update_attribute(@serial_number, 'warranty_reference', warranty_reference)
    end
  end
end
