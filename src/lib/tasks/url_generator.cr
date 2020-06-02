require "yaml"

module UrlGenerator
  private def self.get_urls(urls_file)
    # It's also possible to define a schema for the
    #   yaml file you are reading.
    file_lines = File.read urls_file
    YAML.parse(file_lines)["urls"].as_a.map(&.as_s)
  end

  def self.run(urls_file, url_stream)
    # Tradeoffs of one fiber here vs. a fiber for each
    # url? .send will block this fiber until .receive is called
    # What is the cost of spinning up tons of fibers?
    spawn do
      get_urls(urls_file).each { |url| url_stream.send url }
    end
  end
end
