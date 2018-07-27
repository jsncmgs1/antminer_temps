require 'json'
require 'socket'
require './stats'

module AntMiner
  class Config
    attr_accessor :port, :writer, :reader
  end

  class Client
    attr_reader :config
    attr_accessor :stats

    def initialize
      @config = Config.new
      yield @config
    end

    def monitor
      at_exit do
        puts '*' * 30
        puts "\nClosing socket server..."
        puts "\nClosing sockets..."
        puts "\nexiting..."
      end

      puts '=' * 45
      puts "Getting stats from #{$addresses.count} miners\n"

      loop do
        sleep 1

        $addresses.each do |address|
          begin
            socket = TCPSocket.open(address, port)
          rescue Errno::ETIMEDOUT
            puts "Could not establish connection to miners. Ensure your miners are on, connected to the network, and you input the addresses correctly"
            exit
          end
          json = Api::Stats.get_temps(socket)
          socket.close
          $stats[address] << json
          puts "Logged stats for #{address}"
        end
      end
    end

    def port      ; config.port      end
    def writer    ; config.writer    end
    def reader    ; config.reader    end
  end
end
