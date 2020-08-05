module AvgResponseTime

  def self.run(success_stream, width : Int32) : Channel({StatusChecker::Success, Time::Span})
    Channel({StatusChecker::Success, Time::Span}).new.tap do |out_stream|
      spawn do
        values_window = Deque(Time::Span).new(width)
        loop do
          status = success_stream.receive.as(StatusChecker::Success)
          values_window.shift? if values_window.size >= width
          values_window << status.response_time
          p values_window
          # or use values_window.size?
          moving_avg = values_window.reduce(&.+) / width
          out_stream.send( {status, moving_avg} )
        end
      rescue Channel::ClosedError
        # log
      ensure
        out_stream.close
      end
    end
  end
end
