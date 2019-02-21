require 'iop'
require 'digest'


module IOP


  class DigestComputer

    include Feed
    include Sink

    attr_reader :digest

    def initialize(digest)
      @digest = digest
    end

    def process(data = nil)
      digest.update(data) unless data.nil?
      super
    end

  end


end