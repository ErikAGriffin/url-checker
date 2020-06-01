require "http/client"
require "yaml"

# Alternate syntax: Proc(Arg1Type, ReturnType).new {}
def get_urls
  # It's also possible to define a schema for the
  #   yaml file you are reading.
  urls_file = File.read "./urls.yml"
  YAML.parse(urls_file)["urls"].as_a.map(&.as_s)
end

puts "Starting Program"

get_status = Proc(String, {String, Int32 | Exception}).new {|url|
  begin
    puts "Calling #{url}"
    res = HTTP::Client.get url
    {url, res.status_code}
  rescue e : Socket::ConnectError | Socket::Addrinfo::Error
    {url, e}
  ensure
    puts "Done!"
  end
}

url_stream = Channel(String).new
result_stream = Channel({String, Int32 | Exception}).new

puts "Spawning get_urls fiber"
# Tradeoffs of one fiber here vs. a fiber for each
# url? .send will block this fiber until .receive is called
# What is the cost of spinning up tons of fibers?
spawn do
  puts "Iterating over urls"
  get_urls.each do |url|
    puts "got a url: #{url}"
    # Channels are blocking when send is called on them
    url_stream.send url
  end
  # get_urls.each { |url| url_stream.send url }
end

2.times do
  puts "Spawning Worker"
  spawn do
    loop do
      puts "Receiving url"
      url = url_stream.receive
      result = get_status.call url
      puts "Sending Result #{url}: #{result.last}"
      result_stream.send result
    end
  end
end

puts "looping result_stream.receive.."
loop do
  puts result_stream.receive
end

# puts get_urls.map(&get_status).join("\n")

puts "Goodbye, cruel world."
