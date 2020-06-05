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
          # !!-- Test using just .close vs. the supervisor
          # url_status_stream.close
          countdown.send nil
        end
      end # workers.times
    end   # Channel.new
  end
end
