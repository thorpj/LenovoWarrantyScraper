require_relative 'LenovoWarrantyScraper/version'
require_relative 'LenovoWarrantyScraper/elements'

module LenovoWarrantyScraper
  class Error < StandardError; end
  # Your code goes here...

  class << self
    attr_accessor :driver, :wait, :elements
  end

  DotBot.elements = {}

  class Scraper
    attr_reader :location

    def initialize(location)
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
      DotBot.driver = @driver
      DotBot.wait = @wait
      @driver.manage.timeouts.implicit_wait = 10 # seconds
      @wait = Selenium::WebDriver::Wait.new(timeout: 10) # seconds
      @driver.navigate.to @url
      login_form
      new_booking_form
    end
  end
end