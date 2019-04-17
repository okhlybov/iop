require 'iop'


module IOP


  #
  # Feed class to send arbitrary string in blocks of specified size.
  #
  # ### Use case: split the string into 3-byte blocks and reconstruct it.
  #
  #     require 'iop/string'
  #     ( IOP::StringSplitter.new('Hello IOP', 3) | IOP::StringMerger.new ).process!
  #
  # @since 0.1
  #
  class StringSplitter

    include Feed

    # Creates class instance.
    # @param string [String] string to be sent in blocks
    # @param block_size [Integer] size of block the string is split into
    def initialize(string, block_size: DEFAULT_BLOCK_SIZE)
      @string = string
      @block_size = block_size
    end

    def process!
      offset = 0
      (0..@string.size / @block_size - 1).each do
        process(@string[offset, @block_size])
        offset += @block_size
      end
      process(offset.zero? ? @string : @string[offset..-1]) unless offset == @string.size
      process
    end

  end


  #
  # Sink class to receive data blocks and merge them into a single string.
  #
  # ### Use case: read current source file into a string.
  #
  #     require 'iop/file'
  #     require 'iop/string'
  #     ( IOP::FileReader.new($0) | (s = IOP::StringMerger.new) ).process!
  #     puts s.to_s
  #
  # The actual string assembly is performed by the {#to_s} method.
  #
  # @note instance of this class can be used to collect data from multiple processing runs.
  #
  # @since 0.1
  #
  class StringMerger

    include Sink

    # Creates class instance.
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

    # Returns concatenation of all received data blocks into a single string.
    # @return [String]
    def to_s
      string = IOP.allocate_string(@size)
      @data.each {|x| string << x}
      string
    end

  end


end