require "log"

backend = Log::IOBackend.new
backend.formatter = ->(entry : Log::Entry, io : IO) {
  label = entry.severity.label
  source = entry.source
  io << label <<
  " [" << entry.timestamp.to_s("%H:%M:%S") << "] " <<
  "#" << source << "." << Fiber.current.name <<
  ": " << entry.message
  if entry.context.size > 0
    io << " -- " << entry.context
  end
  if ex = entry.exception
    io << " -- " << ex.class << ": " << ex
  end
}
Log.builder.bind "*", :debug, backend

# Log.builder.bind "db.*", :warning, backend

# Allows for auto-instantiation of a
# Log constant within the given class.
module Logging
  macro extended
    # I can use macro if statements
    # to change this initialization if the
    # @type == Program, to not wrap my main
    # file in a module, if that's something I want
    Log = ::Log.for self
  end
end
