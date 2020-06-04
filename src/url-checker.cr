require "./lib/config"
require "./lib/logging"
require "./lib/stats"
require "./lib/concurrency_util"
require "./lib/tasks/status_checker"
require "./lib/tasks/stats_logger"
require "./lib/tasks/printer"

# extend Logging
module Main
  extend self
  extend Logging

  CONFIG  = Config.load
  WORKERS = CONFIG.workers
  PERIOD  = CONFIG.period

  def run
    Log.info { "Starting Program" }

    url_stream = Channel(String).new
    url_status_stream = Channel({String, Int32 | Exception}).new
    stats_stream = Channel(Stats::StatStream).new

    every PERIOD do
      Config.load.urls >> url_stream
    end

    WORKERS.times do
      StatusChecker.run(url_stream, url_status_stream)
    end

    StatsLogger.run(url_status_stream, stats_stream)

    Printer.run(stats_stream)

    sleep
  end
end

Main.run
