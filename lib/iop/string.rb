require 'iop'


module IOP


  class StringSplitter

    include Feed

    def initialize(string, block_size)
      @string = string
      @block_size = block_size
    end

    def process!
      offset = 0
      (0..@string.size / @block_size - 1).each do |i|
        process(@string[offset, @block_size])
        offset += @block_size
      end
      process(offset.zero? ? @string : @string[offset..-1]) unless offset == @string.size
      process
    end

  end


  class StringMerger

    include Sink

    def initialize
      @size = 0
      @data = []
    end

    def process(data = nil)
      unless data.nil?
        @data << data.dup # CHECKME is duplication really needed when the upstream continuously resending its internal data buffer with new contents
        @size += data.size
      end
    end

    def to_s
      string = IOP.allocate_string(@size)
      @data.each {|x| string << x}
      string
    end

  end


end