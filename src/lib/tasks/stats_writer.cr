require "../stats"
require "../logging"

module StatsWriter
  extend Logging

  def self.run(url_status_stream, stats_store : StatsStore)
    spawn(name: "stats_writer") do
      loop do
        case received = url_status_stream.receive
        # !!-- turn tuple into a type, so that we don't have to make assumptions about the status code of the response
        when {StatusChecker::Success, Time::Span}
          status_obj, avg_response_time = received.as({StatusChecker::Success, Time::Span})
          stats_store.log_success(status_obj.url, avg_response_time)
        # Why is the Success also here? Because we cast the value
        # in AvgResponseTime?
        when StatusChecker::Failure, StatusChecker::Success
          stats_store.log_failure(received.url)
        else
          Log.error { "else block reached in StatsWriter" }
          exit
        end
      rescue Channel::ClosedError
        Log.info { "Shutting down" }
        break
      end # loop
    end   # spawn
  end
end
