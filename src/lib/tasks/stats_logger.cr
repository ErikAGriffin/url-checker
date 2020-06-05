require "../stats"
require "../logging"

module StatsLogger
  extend Logging

  def self.run(url_status_stream)
    Channel(Stats::StatStream).new.tap do |stats_stream|
      spawn(name: "stats_logger") do
        Log.info { "Looping url_status_stream.receive.." }
        stats = Stats.new
        loop do
          url, result = url_status_stream.receive
          case result
          when Int32
            if result < 400
              stats.log_success url
            else
              stats.log_failure url
            end
          when Exception
            stats.log_failure url
          end
          data = stats.map { |url, result| {url, result} }
          stats_stream.send data
        end
      rescue Channel::ClosedError
        Log.info { "Channel Closed" }
      ensure
        stats_stream.close
      end
    end
  end
end
