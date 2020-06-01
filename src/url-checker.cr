require "http/client"
require "yaml"


puts "Starting Program"

def get_urls
  # It's also possible to define a schema for the
  #   yaml file you are reading.
  urls_file = File.read "./urls.yml"
  YAML.parse(urls_file)["urls"].as_a.map(&.as_s)
end

get_status = Proc(String, {String, Int32 | Exception}).new {|url|
  begin
    res = HTTP::Client.get url
    {url, res.status_code}
  rescue e : Socket::ConnectError | Socket::Addrinfo::Error
    {url, e}
  end
}

url_stream = Channel(String).new
result_stream = Channel({String, Int32 | Exception}).new

# Tradeoffs of one fiber here vs. a fiber for each
# url? .send will block this fiber until .receive is called
# What is the cost of spinning up tons of fibers?
spawn do
  get_urls.each { |url| url_stream.send url }
end

2.times {
  spawn do
    loop do
      url = url_stream.receive
      result = get_status.call url
      result_stream.send result
    end
  end
}

puts "Looping result_stream.receive.."
stats = Hash(String, {success: Int32, failure: Int32}).new({success: 0, failure: 0})
loop do
  url, result = result_stream.receive
  case result
  when Int32
    if result < 400
      stats[url] = {
        success: stats[url]["success"] + 1,
        failure: stats[url]["failure"]
      }
    else
      stats[url] = {
        success: stats[url]["success"],
        failure: stats[url]["failure"] + 1
      }
    end
  when Exception
    stats[url] = {
      success: stats[url]["success"],
      failure: stats[url]["failure"] + 1
    }
  end
  p stats
end

# puts get_urls.map(&get_status).join("\n")
