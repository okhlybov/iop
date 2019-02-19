require 'iop'


module IOP


  class ZlibCompressor

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
      @deflate = Zlib::Deflate.new(*@args)
      super
    ensure
      @deflate.close
    end
  end


  class ZlibDecompressor

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
      @inflate = Zlib::Inflate.new(*@args)
      super
    ensure
      @inflate.close
    end
  end


  class GzipCompressor

    include Feed
    include Sink

    def initialize(*args)
      @args = args
    end

    def process(data = nil)
      if data.nil?
        @compressor.finish
        super
      else
        @compressor.write(data)
      end
    end

    def write(data)
      downstream&.process(data)
    end

    def process!
      @compressor = Zlib::GzipWriter.new(self, *@args)
      super
    ensure
      @compressor.close unless @compressor.nil?
    end
  end


  class GzipDecompressor < ZlibDecompressor
    def initialize
      super(16)
    end
  end


end