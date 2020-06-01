require "http/client"
require "yaml"

# Alternate syntax: Proc(Arg1Type, ReturnType).new {}
get_urls = -> {
  # It's also possible to define a schema for the
  #   yaml file you are reading.
  urls_file = File.read "./urls.yml"
  YAML.parse(urls_file)["urls"].as_a.map(&.as_s)
}
# ? Why use a Proc instead of a method definition ?
#   Interesting.. a proc can be passed to a map
#   as the block argument.

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

puts get_urls.call.map(&get_status).join("\n")

puts "Goodbye, cruel world."
