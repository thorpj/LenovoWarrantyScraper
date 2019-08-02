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



module LenovoWarrantyScraper
  class Error < StandardError; end
  # Your code goes here...

  class << self
    attr_accessor :driver, :wait, :elements
  end
  scraper = LenovoWarrantyScraper::Scraper.new


end