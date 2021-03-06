require "tablo"
require "../logging"

module Printer
  extend Logging

  # Why do I not need a type definition here?
  def self.run(stats_stream)
    Channel(Nil).new.tap do |termination_channel|
      spawn(name: "printer") do
        loop do
          table_data = stats_stream.receive.map do |(url, result)|
            [url, result[:success], result[:failure]]
          end
          table = Tablo::Table.new(table_data) do |t|
            t.add_column("URL", width: 32) { |n| n[0] }
            t.add_column("Successes", width: 9) { |n| n[1] }
            t.add_column("Failures", width: 9) { |n| n[2] }
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
