#
# The basic control flow for an {IOP}-aware pipe is as follows:
#
# 1. The pipe is constructed from one or more {IOP}-aware class instances. The two or more objects are linked together with the +|+ operator implemented as {Feed#|} by default.
# 2. The actual processing is then triggered by the {Sink#process!} method of the *last* object in the pipe. By default, this method calls the same method of the upstream object thus forming the stack of nested calls for all objects in the pipe.
# 3. Upon reaching the very *first* object in the pipe (which by definition has no upstream neighbour).
#
module IOP


  VERSION = '0.1'


  # @private
  if RUBY_VERSION >= '2.4'
    def self.allocate_string(size)
      String.new(capacity: size)
    end
  else
    def self.allocate_string(size)
      String.new
    end
  end


  #
  # @since 0.1
  #
  module Feed

    #
    # Commences the data processing operation.
    #
    # @abstract
    #
    # @note this method should be implemented in concrete classes including this module.
    #
    # Refer to {Sink#process!} for more information.
    #
    def process!
      raise
    end
    remove_method :process!

    #
    # Sends the data block downstream.
    #
    # @note by convention, the very last call of this method should pass +nil+ to indicate the end-of-data.
    #
    # This implementation simply passes through the received data block downstream if there exists an attached object otherwise the data is simply thrown away.
    #
    # The overriding method in concrete class which includes {Feed} would normally want to call this one as +super+ after performing specific actions.
    #
    def process(data = nil)
      downstream&.process(data) # Ruby 2.3+
    end

    #
    # Returns the downstream object or +nil+ if +self+ is the last object in processing pipe.
    #
    attr_reader :downstream

    #
    # Links +self+ and +downstream+ together forming a processing pipe.
    #
    # The subsequent objects may be linked in turn.
    #
    def |(downstream)
      downstream.upstream = self
      @downstream = downstream
    end

  end


  #
  # @since 0.1
  #
  module Sink

    #
    # Calls {#process!} method of the upstream object.
    #
    def process!
      upstream.process!
    end

    #
    # @abstract
    #
    # @note this method should be implemented in concrete classes including this module.
    #
    # Refer to {Feed#process} for more information.
    #
    def process(data = nil)
      raise
    end
    remove_method :process

    #
    # Returns the upstream object or +nil+ if +self+ is the first object in processing pipe.
    #
    attr_accessor :upstream

  end


  module SegmentReader

    include Feed

    def read!(size)
      @size = size
      @read = 0
      self
    end

    private def done?
      @read >= @size
    end

    def process!
      unless @buffer.nil?
        if @buffer.size > @size
          process(@buffer[0, @read = @size])
          @buffer = (@buffer.size == @size) ? nil : @buffer[@size..-1]
          process
        else
          @read = @buffer.size
          process(@buffer)
          @buffer = nil
        end
      end
    end

  end


end