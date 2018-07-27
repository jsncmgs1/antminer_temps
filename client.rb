require 'json'
require 'socket'
require './stats'

module AntMiner
  class Config
    attr_accessor :addresses, :port, :writer, :ws, :reader
  end

  class Client
    attr_reader :config
    attr_accessor :stats

    def initialize
      @stats  = {}
      @config = Config.new
      yield @config
      addresses.each { |a| stats[a] = [] }
      reader.close
    end

    def monitor
      at_exit do
        writer.close
        puts '*' * 30
        puts "\nClosing socket server..."
        Process.kill 9, ws
        puts "\nClosing sockets..."
        puts "\nexiting..."
      end

      puts '*' * 45
      puts "Getting stats from #{addresses.count} miners\n"
      puts '*' * 45

      loop do
        sleep 1

        addresses.each do |address|
          begin
            socket = TCPSocket.open(address, port)
          rescue Errno::ETIMEDOUT
            puts "Could not establish connection to miners. Ensure your miners are on, connected to the network, and you input the addresses correctly"
            exit
          end
          json = Api::Stats.get_temps(socket)
          socket.close
          stats[address] << json
          writer.puts json
          puts "Logged stats for #{address}"
        end
      end
    end

    def addresses ; config.addresses end
    def port      ; config.port      end
    def writer    ; config.writer    end
    def ws        ; config.ws        end
    def reader    ; config.reader    end
  end
end
