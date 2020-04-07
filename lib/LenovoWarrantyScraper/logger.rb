module LenovoWarrantyScraper
  require 'logger'

  class MultiIO
    def initialize(*targets)
      @targets = targets
    end

    def write(*args)
      @targets.each {|t| t.write(*args)}
    end

    def close
      @targets.each(&:close)
    end
  end

  def self.create_logger(file = true)
    if file
      $logger = Logger.new MultiIO.new STDOUT
    else
      @settings = YAML.load_file(File.expand_path(File.join(File.dirname(__dir__), '../config/settings.yaml')))
      file = File.open(File.join(File.join(File.dirname(__FILE__), '../../'), @settings[:log_path]), 'a')
      $logger = Logger.new MultiIO.new(STDOUT, file)
    end
  end


end