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

abstract class Channel(T)
  def partition(&predicate : T -> Bool) : {Channel(T), Channel(T)}
    {Channel(T).new, Channel(T).new}.tap do |pass, fail|
      spawn do
        loop do
          value = self.receive
          predicate.call(value) ? pass.send(value) : fail.send(value)
        end
      rescue Channel::ClosedError
        pass.close
        fail.close
      end
    end
  end

  def |(other : Channel(K)) : Channel(T | K) forall K
    Channel(T | K).new.tap do |output_stream|
      spawn do
        loop do
          output_stream.send Channel.receive_first(self, other)
        end
      rescue Channel::ClosedError
        output_stream.close
      end
    end
  end

  def map(workers : Int32 = 1, &block : T -> K) : Channel(K) forall K
    # This supervisor pattern ensures all workers finish the
    # current task they are on and are able to pass it into
    # the downstream channel before it is closed (vs. the
    # first worker that finishes closing the channel and
    # blocking it for all the other workers).
    # ..
    # !!-- Why don't we have to close the countdown channel?
    #   Is it because the run method terminates when the
    #   Channel::Closed propagates?
    Channel(K).new.tap do |output_stream|
      countdown = Channel(Nil).new(workers)
      spawn(name: "supervisor") do
        workers.times { countdown.receive }
        output_stream.close
      end
      workers.times do |w_i|
        spawn(name: "worker_#{w_i}") do
          loop do
            result = block.call self.receive
            output_stream.send result
          end
        rescue Channel::ClosedError
          # Log.info { "input stream was closed" }
        ensure
          countdown.send nil
        end
      end # workers.times
    end   # Channel.new
  end     # end #map

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
