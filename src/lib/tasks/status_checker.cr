require "http/client"
require "../logging"

module StatusChecker
  extend Logging

  private def self.get_status(url)
    res = HTTP::Client.get url
    {url, res.status_code}
  rescue e : Socket::ConnectError | Socket::Addrinfo::Error
    {url, e}
  end

  def self.run(url_stream, workers : Int32)
    Channel({String, Int32 | Exception}).new.tap do |url_status_stream|
      # This supervisor pattern ensures all workers finish the
      # current task they are on and are able to pass it into
      # the downstream channel before it is closed (vs. the
      # first worker that finishes closing the channel and
      # blocking it for all the other workers).
      countdown = Channel(Nil).new(workers)
      spawn(name: "supervisor") do
        workers.times { countdown.receive }
        url_status_stream.close
      end
      workers.times do |w_i|
        spawn(name: "worker_#{w_i}") do
          loop do
            url = url_stream.receive
            result = get_status url
            url_status_stream.send result
          end
        rescue Channel::ClosedError
          Log.info { "input stream was closed" }
        ensure
          countdown.send nil
        end
      end # workers.times
    end   # Channel.new
  end
end
