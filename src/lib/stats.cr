class Stats
  alias StatRecord = NamedTuple(url: String, success: Int32, failure: Int32, avg_response_time: Time::Span)
  alias StatStream = Array({String, Stats::StatRecord})

  include Enumerable({String, StatRecord})
  delegate each, to: @stats
  delegate values, to: @stats

  # !!--NEXT2: Understand exactly what's going on here
  # for the generation of automatic values for missing keys.
  def initialize
    @stats = Hash(String, StatRecord).new do |hash, key|
      {url: key, success: 0, failure: 0, avg_response_time: 0.seconds}
    end
  end

  def log_success(url : String, avg_response_time : Time::Span)
    current = @stats[url]
    @stats[url] = current.merge(
      {success: current[:success] + 1}
    )
  end

  def log_failure(url : String)
    current = @stats[url]
    @stats[url] = current.merge(
      {failure: current[:failure] + 1}
    )
  end
end
