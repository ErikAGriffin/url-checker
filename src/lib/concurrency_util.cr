# What does this  : -> T do?
def every(period : Time::Span, &block : -> T) forall T
  spawn do
    loop do
      block.call
      sleep period
    end
  end
end

module Enumerable(T)
  def >>(channel : Channel(T))
    spawn do
      each { |value| channel.send value }
    end
  end
end
