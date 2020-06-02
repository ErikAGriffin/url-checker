class Stats
  alias StatRecord = NamedTuple(success: Int32, failure: Int32)
  alias StatStream = Array({String, Stats::StatRecord})

  include Enumerable({String, StatRecord})
  delegate each, to: @stats

  def initialize
    @stats = Hash(String, StatRecord).new({success: 0, failure: 0})
  end

  def log_success(url : String)
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
