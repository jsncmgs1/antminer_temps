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
