require "./client"
require 'em-websocket'

rd, wt = IO.pipe

pid = fork do
  wt.close
  EventMachine::WebSocket.start(host: "0.0.0.0", port: 8080) do |ws|
    ws.onopen    { ws.send "yeehaw" }
    ws.onmessage { |msg| ws.send "Pong: #{rd.gets}" }
    ws.onclose   { puts "WebSocket closed" }
  end
end

client = AntMiner::Client.new do |config|
  config.addresses = File.read('addresses.txt').split(/\n/)
  config.port = 4028
  config.writer = wt
  config.reader = rd
  config.ws = pid
end

client.monitor
