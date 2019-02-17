module IOP


  VERSION = '0.1'


  if RUBY_VERSION >= '2.4'
    def self.allocate_string(size)
      String.new(capacity: size)
    end
  else
    def self.allocate_string(size)
      String.new
    end
  end


  module Feed

    # def process!

    def process(data = nil)
      downstream&.process(data) # Ruby 2.3+
    end

    attr_reader :downstream

    def |(downstream)
      downstream.upstream = self
      @downstream = downstream
    end

  end


  module Sink

    def process!
      upstream.process!
    end

    # def process(data)

    attr_accessor :upstream

  end


end