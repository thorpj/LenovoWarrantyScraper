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

  def self.run
    runner = LenovoWarrantyScraper::Runner.new
    runner.run
  end

  def self.single_claim(secrets, settings, serial_number, account, ticket_number, parts, failure_description, comments)
    runner = LenovoWarrantyScraper::Runner.new(secrets, settings)
    warranty_reference = runner.single_claim(serial_number, account, ticket_number, parts, failure_description, comments)
    warranty_reference
  end
end