require 'bundler/setup'
require 'yaml'
require 'selenium-webdriver'
require 'date'
require 'logger'
require 'byebug'
require 'pp'


require_relative 'LenovoWarrantyScraper/version'
require_relative 'LenovoWarrantyScraper/runner'
require_relative 'LenovoWarrantyScraper/elements'
require_relative 'LenovoWarrantyScraper/scraper'
require_relative 'LenovoWarrantyScraper/state'
require_relative 'LenovoWarrantyScraper/logger'



module LenovoWarrantyScraper
  class Error < StandardError; end
  class << self
    attr_accessor :driver, :wait, :elements
  end
  create_logger

  def self.run
    runner = LenovoWarrantyScraper::Runner.new
    runner.run
  end

  def self.single_claim(secrets, settings, serial_number, account, ticket_number, parts, failure_description, comments, service_type='CLW', authorization_code=nil)
    if !(parts.is_a?(Array))
      if parts.is_a?(String)
        parts = parts.split(' ')
      else
        parts = [parts]
      end
    end

    runner = LenovoWarrantyScraper::Runner.new(secrets, settings)
    warranty_reference = runner.single_claim(serial_number, account, ticket_number, parts, failure_description, comments, service_type, authorization_code)
    warranty_reference
  end

  def self.load_secrets
    path = File.expand_path(File.join(File.dirname(__dir__), 'config/secrets.yaml'))
    YAML.load_file(path)
  end

  def self.load_settings
    path = File.expand_path(File.join(File.dirname(__dir__), 'config/settings.yaml'))
    YAML.load_file(path)
  end


end