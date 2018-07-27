require "./client"
require 'em-websocket'

rd, wt = IO.pipe

pid = fork do
  EventMachine::WebSocket.start(host: "0.0.0.0", port: 8080) do |ws|
    ws.onopen    { ws.send "yeehaw" }
    ws.onmessage { |msg| ws.send "Pong: #{1+1}" }
    ws.onclose   { puts "WebSocket closed" }
  end
end

AntMiner::Client.config do |client|
  client.addresses = File.read('addresses.txt').split(/\n/)
  client.port = 4028
  client.writer = wt
  client.ws = pid
end

AntMiner::Client.new.monitor
