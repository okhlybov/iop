require 'iop'
require 'zstdlib'


module IOP


  class ZstdCompressor

    include Feed
    include Sink

    def initialize(*args)
      @args = args
    end

    def process(data = nil)
      if data.nil?
        super(@deflate.finish)
        super
      else
        super(@deflate.deflate(data))
      end
    end

    def process!
      @deflate = Zstdlib::Deflate.new(*@args)
      begin
        super
      ensure
        @deflate.close
      end
    end
  end


  class ZstdDecompressor

    include Feed
    include Sink

    def initialize(*args)
      @args = args
    end

    def process(data = nil)
      if data.nil?
        super(@inflate.finish)
        super
      else
        super(@inflate.inflate(data))
      end
    end

    def process!
      @inflate = Zstdlib::Inflate.new(*@args)
      begin
        super
      ensure
        @inflate.close
      end
    end
  end

  end