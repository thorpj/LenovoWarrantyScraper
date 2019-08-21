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

  runner = LenovoWarrantyScraper::Runner.new
  runner.scrape
end