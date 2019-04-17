require 'iop'
require 'securerandom'


module IOP


  #
  # Feed class to generate and send a random sequence of bytes of specified size.
  #
  # This is the adapter for standard {SecureRandom} generator module.
  #
  # ### Use case: generate 1024 bytes of random data and compute MD5 hash sum of it.
  #
  #     require 'iop/digest'
  #     require 'iop/securerandom'
  #     ( IOP::SecureRandomGenerator.new(1024) | IOP::DigestComputer.new(Digest::MD5.new) ).process!
  #
  # @since 0.1
  #
  class SecureRandomGenerator

    include Feed

    # Creates class instance.
    # @param size [Integer] total random data size
    # @param block_size [Integer] size of block the data in split into
    def initialize(size, block_size: DEFAULT_BLOCK_SIZE)
      @size = size
      @block_size = block_size
    end

    def process!
      written = 0
      (0..@size/@block_size - 1).each do
        process(SecureRandom.bytes(@block_size))
        written += @block_size
      end
      left = @size - written
      process(SecureRandom.bytes(left)) unless left.zero?
      process
    end

  end


end