require "./lib/config"
require "./lib/logging"
require "./lib/stats"
require "./lib/concurrency_util"
require "./lib/tasks/status_checker"
require "./lib/tasks/stats_logger"
require "./lib/tasks/printer"

# extend Logging
module UrlChecker
  extend self
  extend Logging
  include ConcurrencyUtil

  CONFIG  = Config.load
  WORKERS = CONFIG.workers
  PERIOD  = CONFIG.period

  def run
    Log.info { "Starting Program" }

    interrupt = Channel(Nil).new

    Signal::INT.trap do
      Log.info { "Triggering shutdown..." }
      interrupt.send nil
    end

    url_stream = every(PERIOD, interrupt) do
      Config.load.urls
    end

    url_status_stream = StatusChecker.run(url_stream, workers: WORKERS)

    stats_stream = StatsLogger.run url_status_stream

    Printer.run(stats_stream).receive?

    Log.info { "Goodbye" }
  end
end

UrlChecker.run
