require './client'
require 'em-websocket'

$addresses = File.read('addresses.txt').split(/\n/)
$stats = {}
$addresses.each { |a| $stats[a] = [] }

thread1 = Thread.new do
  EventMachine::WebSocket.start(host: '0.0.0.0', port: 8080) do |ws|
    ws.onopen { ws.send 'yeehaw' }
    ws.onmessage { |msg|
      ip, _command = msg.split(/:/)
      latest = $stats[ip].last
      ws.send latest.to_json
    }
    ws.onclose { puts 'WebSocket closed' }
  end
end

at_exit do
  Thread.kill thread1
end

client = AntMiner::Client.new do |config|
  config.port = 4028
end

client.monitor
