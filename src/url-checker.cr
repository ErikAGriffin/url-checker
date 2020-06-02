require "http/client"
require "yaml"
require "tablo"
require "./lib/stats"

puts "Starting Program"

def get_urls
  # It's also possible to define a schema for the
  #   yaml file you are reading.
  urls_file = File.read "./urls.yml"
  YAML.parse(urls_file)["urls"].as_a.map(&.as_s)
end

get_status = Proc(String, {String, Int32 | Exception}).new { |url|
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
stats = Stats.new
loop do
  url, result = result_stream.receive
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
  p stats
  table_data = stats.map do |url, result|
    [url, result["success"], result["failure"]]
  end
  table = Tablo::Table.new(table_data) do |t|
    t.add_column("URL", width: 32) { |n| n[0] }
    t.add_column("Successes", width: 9) { |n| n[1] }
    t.add_column("Failures", width: 9) { |n| n[2] }
  end
  puts table
end
