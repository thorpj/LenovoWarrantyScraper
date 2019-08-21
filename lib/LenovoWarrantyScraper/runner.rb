module LenovoWarrantyScraper


  class Runner
    def initialize
      @scraper = LenovoWarrantyScraper::Scraper.new
      @settings = YAML.load_file(File.join(File.dirname(__dir__), '../config/settings.yaml'))
      @state_manager = LenovoWarrantyScraper::StateManager.new
      @serial_number = nil
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

    def scrape
      @serial_number = 'R90SBAGV'
      @scraper.test(@serial_number)
    end

    def failure_sleep(attempts)
      time = @settings['failure_sleep_times'][attempts]
      sleep(time)
    end

    def submit_claim
      attempts = 0
      @state_manager.add_new(@serial_number)
      status = @state_manager.get_attribute(@serial_number, 'status')
      warranty_reference = @state_manager.get_attribute(@serial_number, 'warranty_reference')
      if status != 'submitted' || warranty_reference.nil?
          $logger.debug "Lodging claim"
          while attempts < @settings['max_attempts']
            begin
              warranty_reference = @scraper.make_claim(@serial_number)
              unless warranty_reference.nil? || warranty_reference == ''
                update_status(:submitted)
                update_warranty_reference(warranty_reference)
                $logger.debug "Claim successful #{@serial_number} #{warranty_reference}"
                break
              end
            rescue OutOfWarrantyError
              $logger.debug "Failed to submit claim - out of warranty, retrying"
              update_status(:out_of_warranty)
              break
            rescue => e
              # $logger.debug e
              $logger.debug "Failed to submit claim, retrying"
            end
            @scraper.close
            attempts += 1
            failure_sleep(attempts)
          end
        if attempts >= 5
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