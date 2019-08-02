module LenovoWarrantyScraper
  require 'csv'

  class State
    def initialize
      @secrets = YAML.load_file(File.join(File.dirname(__dir__), '../config/secrets.yaml'))
      @settings = YAML.load_file(File.join(File.dirname(__dir__), '../config/settings.yaml'))
    end

    def root_path
      File.join(File.dirname(__FILE__), '../../')
    end

    def load_input_file
      path = File.join(root_path, @settings['input_csv_path'])
      CSV.read(path)
    end

    def load_status_file
      path = File.join(root_path, @settings['status_csv_path'])
      CSV.parse(path, headers: true)
    end
  end
end