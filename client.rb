require 'json'
require 'socket'
require 'net/http'

module AntMiner
  class Client
    class << self
      attr_accessor :addresses, :port, :stats, :writer, :ws, :reader
      attr_reader :sockets

      def config
        @sockets = {}
        @stats   = {}
        yield self
      end
    end

    at_exit do
      writer.close
      puts '*' * 30
      puts "\nClosing socket server..."
      Process.kill 9, ws
      puts "\nClosing sockets..."
      puts "\nexiting..."
      sockets.each {|_, socket| socket.close }
    end


    def initialize
      reader.close
      addresses.each { |a| stats[a] = [] }
    end

    def monitor
      trap('INT') { exit }

      puts '*' * 45
      puts "Getting stats from #{addresses.count} miners\n"
      puts '*' * 45

      loop do
        sleep 1

        addresses.each do |address|
          socket = TCPSocket.open(address, port)
          json = Api::Stats.get_temps(socket)
          socket.close
          stats[address] << json
          writer.puts json
          puts "Logged stats for #{address}"
        end
      end
    end

    # must unfuck this
    #
    def addresses
      self.class.addresses
    end

    def port
      self.class.port
    end

    def sockets
      self.class.sockets
    end

    def stats
      self.class.stats
    end

    def writer
      self.class.writer
    end

    def ws
      self.class.ws
    end

    def reader
      self.class.reader
    end
  end

  module Api
    module Stats
      extend self

      def get_temps(socket)
        socket.write({command: "stats"}.to_json)
        response = socket.read.strip

        parse(JSON.parse(response))
      rescue JSON::ParserError => e

        # stats command generates broken json, this gets what we need
        if nested_json = e.message.match(/\{.*\}\]/)
          response = nested_json[0]
        end

        response = response.gsub("]", "")

        parse(JSON.parse(response))
      end

      def parse(stats)
        {
          pcb_1: stats["temp1"],
          pcb_2: stats["temp2"],
          pcb_3: stats["temp3"],
          chip_1: stats["temp2_1"],
          chip_2: stats["temp2_2"],
          chip_3: stats["temp2_3"]
        }
      end
    end
  end
end
