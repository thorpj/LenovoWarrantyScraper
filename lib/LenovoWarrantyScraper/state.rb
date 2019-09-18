module LenovoWarrantyScraper
  require 'csv'

  class StateManager
    attr_accessor :state
    attr_reader :input

    def initialize
      @secrets = YAML.load_file(File.join(File.dirname(__dir__), '../config/secrets.yaml'))
      @settings = YAML.load_file(File.join(File.dirname(__dir__), '../config/settings.yaml'))
      @state = load_state_file
      @input = load_input_file
      @headers = csv_headers(state_csv_path)
    end

    def root_path
      File.join(File.dirname(__FILE__), '../../')
    end

    def input_csv_path
      File.join(root_path, @settings['input_csv_path'])
    end

    def state_csv_path
      File.join(root_path, @settings['state_csv_path'])
    end

    def load_input_file
      begin
        CSV.read(input_csv_path)
      rescue Errno::ENOENT, ::IOError => e
        puts "Error reading input csv #{input_csv_path}"
        []
      end
    end

    def load_state_file
      begin
        file = File.open(state_csv_path, "r")
        CSV.parse(file, headers: true)
      rescue Errno::ENOENT => e
        puts "state file missing, creating new file at #{state_csv_path}"
        []
      rescue IOError
        puts "Error reading state csv #{state_csv_path}"
        []
      end
    end

    def save_state_file
      CSV.open(state_csv_path, "w") do |csv|
        csv << @headers
        @state.each do |line|
          csv << line
        end
      end
    end

    def add_new(serial_number)
      if (find_index(serial_number)).nil?
        requires_reload = false
        if @state.headers.length == 0
          requires_reload = true
        end
        line = @headers.length.times.map { |x| nil }
        line[0] = serial_number
        @state << line
        if requires_reload
          save_state_file
          @state = load_state_file
        end
      end
    end

    def find_index(serial_number)
      i = 0
      index = nil
      rows = @state.to_a
      rows.each do |row|
        row.each do |cell|
          if cell == serial_number
            index = i - 1
            break
          end
        end
        break unless index.nil?
        i += 1
      end
      index
    end

    def update_attribute(serial_number, attribute, value)
      index = find_index(serial_number)
      if index.nil?
        $logger.debug "Unable to update attribute - serial not found. Creating now."
        add_new(serial_number)
      else
        @state[index][attribute] = value
        $logger.debug "Updating #{attribute} to #{value}"
      end
    end

    def get_attribute(serial_number, attribute)
      index = find_index(serial_number)
      unless index.nil?
        @state[index][attribute]
      end
    end

    def csv_headers(path)
      headers = CSV.read(path)
      unless headers.kind_of?(Array)
        headers = headers.to_a
      end
      headers.first
    end
  end
end

