require 'json'
require 'socket'
require 'net/http'

module AntMiner
  class Client
    class << self
      attr_accessor :addresses, :port, :stats, :writer, :ws
      attr_reader :sockets

      def config
        @sockets = {}
        @stats   = {}
        yield self
      end
    end

    at_exit do
      Process.kill 9, ws
      puts '*' * 30
      puts "\nClosing sockets..."
      puts "\nexiting..."
      sockets.each {|_, socket| socket.close }
    end


    def initialize
      writer.write "FOOOOOOOOOOOOOOOOO"
      writer.close
      addresses.each do |a|
        # sockets << a
        # sockets[a] = TCPSocket.open(a, port)
        stats[a] = []
      end
    end

    def monitor
      trap('INT') { exit }

      puts '*' * 45
      puts "Getting stats from #{addresses.count} miners\n"
      puts '*' * 45

      while true do
        sleep 1

        addresses.each do |address|
          socket = TCPSocket.open(address, port)
          json = Api::Stats.get_temps(socket)
          socket.close
          stats[address] << json
          puts "Logged stats for #{address}"
        end
      end
    end

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
