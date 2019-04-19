require 'iop'
require 'digest'


module IOP


  #
  # Filter class to compute digest of the data being passed through.
  # It can be used with digest computing classes from the standard Ruby +digest+ and +openssl+ modules.
  #
  # ### Use case: generate 1024 bytes of random data and compute and print MD5 hash sum of it.
  #
  #     require 'iop/digest'
  #     require 'iop/securerandom'
  #     ( IOP::SecureRandomGenerator.new(1024) | ( d = IOP::DigestComputer.new(Digest::MD5.new)) ).process!
  #     puts d.digest.hexdigest
  #
  # @since 0.1
  #
  class DigestComputer

    include Feed
    include Sink

    # Returns digest object passed to constructor.
    attr_reader :digest


    # Creates class instance.
    #
    # @param digest computer instance to be fed with data
    def initialize(digest)
      @digest = digest
    end

    def process(data = nil)
      digest.update(data) unless data.nil?
      super
    end

  end


end