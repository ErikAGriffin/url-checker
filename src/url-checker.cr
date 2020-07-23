require "./lib/config"
require "./lib/logging"
require "./lib/stats"
require "./lib/concurrency_util"
require "./lib/tasks/status_checker"
require "./lib/tasks/stats_writer"
require "./lib/tasks/printer"
require "./lib/server/stats_store"

module UrlChecker
  extend self
  extend Logging
  include ConcurrencyUtil

  CONFIG  = Config.load
  WORKERS = CONFIG.workers
  PERIOD  = CONFIG.period

  Log.info { "Period is #{PERIOD}, #{PERIOD.class} " }

  def run
    Log.info { "Starting Program" }

    interrupt_url_generator = Channel(Nil).new
    interrupt_ui = Channel(Nil).new

    Signal::INT.trap do
      Log.info { "Triggering shutdown..." }
      interrupt_url_generator.send nil
      interrupt_ui.send nil
    end

    url_stream = every(PERIOD, interrupt_url_generator) do
      Config.load.urls
    end

    url_status_stream = StatusChecker.run(url_stream, workers: WORKERS)

    stats_store = StatsStore.new
    StatsWriter.run(url_status_stream, stats_store)

    stats_stream = every(3.seconds, name: "stats_watcher", interrupt: interrupt_ui) do
      Log.info { "Reading from stats store" }
      [stats_store.get]
    end

    # Receive blocks execution until a value is passed
    # into the channel returned by Printer.run
    # .receive throws an exception if the given channel
    # is closed before a value is received, and
    # .receive? will simply return nil if the channel is
    # closed.
    Printer.run(stats_stream).receive?

    Log.info { "Goodbye" }
  end
end

UrlChecker.run
