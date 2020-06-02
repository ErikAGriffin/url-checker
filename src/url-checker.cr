require "./lib/stats"
require "./lib/tasks/url_generator"
require "./lib/tasks/status_checker"
require "./lib/tasks/stats_logger"
require "./lib/tasks/printer"

puts "Starting Program"

WORKERS = 2
url_stream = Channel(String).new
url_status_stream = Channel({String, Int32 | Exception}).new
stats_stream = Channel(Stats::StatStream).new

UrlGenerator.run("./urls.yml", url_stream)

WORKERS.times do
  StatusChecker.run(url_stream, url_status_stream)
end

StatsLogger.run(url_status_stream, stats_stream)

Printer.run(stats_stream)

sleep
