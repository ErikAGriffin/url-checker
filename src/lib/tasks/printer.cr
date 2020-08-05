require "tablo"
require "../logging"

module Printer
  extend Logging

  def self.run(stats_stream)
    Channel(Nil).new.tap do |termination_channel|
      spawn(name: "printer") do
        loop do
          table_data = stats_stream.receive.map do |stat|
            [stat[:url], stat[:success], stat[:failure], stat[:avg_response_time].total_milliseconds]
          end
          table = Tablo::Table.new(table_data) do |t|
            t.add_column("URL", width: 32) { |n| n[0] }
            t.add_column("Successes", width: 9) { |n| n[1] }
            t.add_column("Failures", width: 9) { |n| n[2] }
            t.add_column("Avg Time") { |n| n[3] }
          end
          puts table
        end
      rescue Channel::ClosedError
        Log.info { "Channel closed" }
        termination_channel.close
      end
    end
  end
end
