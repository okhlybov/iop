require 'iop'
require 'zlib'


module IOP


  class ZlibCompressor

    include Feed
    include Sink

    def initialize(deflate = Zlib::Deflate.new)
      @deflate = deflate
    end

    def process(data = nil)
      super(@deflate.deflate(data))
    end

  end


  class ZlibDecompressor

    include Feed
    include Sink

    def initialize(inflate = Zlib::Inflate.new)
      @inflate = inflate
    end

    def process(data = nil)
      super(@inflate.inflate(data))
    end

  end


end