require "http/client"

module StatusChecker
  private def self.get_status(url)
    res = HTTP::Client.get url
    {url, res.status_code}
  rescue e : Socket::ConnectError | Socket::Addrinfo::Error
    {url, e}
  end

  def self.run(url_stream, url_status_stream)
    spawn do
      loop do
        url = url_stream.receive
        result = get_status url
        url_status_stream.send result
      end
    end
  end
end
