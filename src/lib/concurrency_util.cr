require "./logging"

module ConcurrencyUtil
  extend Logging

  # returns a channel and will send nil
  # to that channel after the 'period'
  def timer(period : Time::Span)
    # Buffered channel with a size of 1, which prevents
    # the channel from blocking this fiber in the event
    # no one reads from that channel. [.new(1)]
    Channel(Nil).new(1).tap do |ch|
      spawn(name: "timer") do
        sleep period
        ch.send nil
      end
    end
  end

  # What does this  : -> T do?
  def every(period : Time::Span,
            interrupt : Channel(Nil) = Channel(Nil).new,
            name : String = "every",
            &block : -> Enumerable(T)) forall T
    Channel(T).new.tap do |out_stream|
      spawn(name: name) do
        loop do
          # select will read from the first channel
          # that returns a value.
          select
          when timer(period).receive
          # Note this spawns a new fiber.  So if the
          # block.call operation takes longer to execute
          # than the period, the number of fibers will
          # continue to grow for the lifetime of the
          # application.
            block.call >> out_stream
          when interrupt.receive
            Log.info { "Shutting down" }
            break
          end
        end
      ensure
        out_stream.close
      end
    end
  end
end

# Monkey Patch to send each value of an enumerable
# to the given channel.
module Enumerable(T)
  def >>(channel : Channel(T))
    spawn do
      each { |value| channel.send value }
    end
  end
end
