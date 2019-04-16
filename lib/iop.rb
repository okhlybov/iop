#
# IOP is intended for constructing the data processing pipelines in a manner of UNIX command-line pipes.
#
# There are three principle types of the pipe nodes which can be composed:
#
# * Feed node.
#
# This is the start point of the pipe. It has no upstream node and may have downstream node.
# Its purpose its to generate blocks of data and send them downstream in sequence.
# A typical feed class is implemented by including the {Feed} module and defining the +#process!+ method
# which calls {Feed#process} method to send the data.
# An example of the feed node is a file reader ({FileReader}) which reads file and sends its contents in blocks.
#
# * Sink node.
#
# This is the end point of the pipe. It has upstream node and no downstream node.
# Its purpose is to consume the received data.
# A typical sink class is implemented by including the {Sink} module and defining the +#process+ method.
# An example of the sink node is a file writer ({FileWriter}) which receives the data in blocks and writes it into file.
#
# * Filter node.
#
# A filter is a pass-through node which sits between feed and sink and therefore has both upstream and downstream nodes.
# The simplest way to create a filter class is to include both {Feed} and {Sink} which manifest
# both mandatory +#process!+ and +#process+ methods. Such filter is a no-op that is it does nothing apart passing
# the received data downstream.
# An example of the filter node is the digest computer ({DigestComputer}) which computes hash sum of the data it passes through.
# In order to perform intended processing of the data a filter class overrides the {Feed#process} method.
#
# The basic control flow for an {IOP}-aware pipe is as follows:
#
# 1. The pipe is constructed from one or more {IOP}-aware class instances. The two or more objects are linked together
# with the | operator implemented as the {Feed#|} method by default.
#
# 2. The actual processing is then triggered by the {Sink#process!} method of the very last object in the pipe.
# By default, this method calls the same method of the upstream node thus forming the stack of nested calls
# for all objects in the pipe.
#
# 3. Upon reaching the very first object in the pipe (which by definition has no upstream node),
# the feed, starts sending blocks of data downstream with the {Feed#process} method. All objects' method implementations
# (except for the one of the last object in the pipe) are expected to push either this or transformed data further downstream.
#
# 4. After all data has been processed the finalizing call +#process(nil)+ signifies the end-of-data after which
# no data should be sent.
#
# In case the {Sink#process!} method is overridden in concrete class it is normally organized as follows:
#
#     def process!
#       # ...initialization code...
#       super
#     ensure
#       # ...finalization code...
#     end
#
# to perform specific setup/cleanup actions, including exception handling and to pass the control flow upstream
# with +super+ call.
#
# Note that when an exception is caught and processed in the overridden +#process!+ method it must be re-raised in order
# for other upstream objects to have a chance to react to it as well.
#
# In case the {Feed#process} is overridden in concrete class it is organized as follows:
#
#     def process(data = nil)
#       # ... do something with data, convert data to new_data...
#       super(new_data)
#     end
#
# The data being sent is expected to be a +String+ of arbitrary size. It is however advisable to detect and omit
# zero-sized strings.
#
# Note that the data passed to this method may be a reusable buffer of some other upstream object therefore a duplication
# (or cloning) should be performed if the data is stored between the method invocations.
#
module IOP


  VERSION = '0.1.0'


  # Default read block size in bytes for adapters which don't have this parameter externally imposed
  DEFAULT_BLOCK_SIZE = 1024**2


  if RUBY_VERSION >= '2.4'
    # @private
    def self.allocate_string(size)
      String.new(capacity: size)
    end
  else
    # @private
    def self.allocate_string(size)
      String.new
    end
  end


  # @private
  INSUFFICIENT_DATA = 'premature end-of-data encountered'.freeze


  # @private
  EXTRA_DATA = 'superfluous data received'.freeze


  # Finds minimum of the values
  def self.min(a, b)
    a < b ? a : b
  end


  #
  # Module to be included into classes which generate and send the data downstream.
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
    # @note by convention, the very last call to this method should pass +nil+ to indicate the end-of-data and no data should be sent afterwards.
    #
    # This implementation simply passes through the received data block downstream if there exists an attached downstream
    # object otherwise the data is simply thrown away.
    #
    # The overriding method in concrete class which includes {Feed} would normally want to call this one as +super+ after
    # performing specific actions.
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
    # The subsequent objects may be linked in turn.
    # @return downstream object
    #
    def |(downstream)
      downstream.upstream = self
      @downstream = downstream
    end

  end


  #
  # Module to be included into classes which receive the upstream data.
  #
  # @since 0.1
  #
  module Sink

    #
    # Commences the data processing operation.
    #
    # This implementation calls {#process!} method of the upstream object.
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


  #
  # @private
  # @note a class including this module must implement the {#next_data} method.
  #
  # @since 0.1
  #
  module BufferingFeed

    include Feed

    def read!(size)
      @left = @size = size
      self
    end

    def process!
      unless @buffer.nil?
        if @buffer.size > @size
          @left = 0
          process(@buffer[0, @size])
          @buffer = @buffer[@size..-1]
        else
          @left -= @buffer.size
          process(@buffer)
          @buffer = nil
        end
      end
      until @left.zero?
        raise EOFError, INSUFFICIENT_DATA if (data = next_data).nil?
        if @left < data.size
          process(data[0, @left])
          @buffer = data[@left..-1]
          @left = 0
        else
          process(data)
          @left -= data.size
        end
      end
      @left = @size = nil
      process
    end

    #
    # @abstract
    #
    # Returns the data portion of non-zero size or +nil+ on EOF.
    #
    # @return [String] data chunk recently read or +nil+
    #
    def next_data
      raise
    end
    remove_method :next_data

  end


end