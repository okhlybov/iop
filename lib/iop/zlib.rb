require 'iop'


module IOP


  class ZlibCompressor

    include Feed
    include Sink

    def initialize(*args)
      @deflate = Zlib::Deflate.new(*args)
    end

    def process(data = nil)
      if data.nil?
        super(@deflate.finish)
        super
      else
        super(@deflate.deflate(data))
      end
    end

  end


  class ZlibDecompressor

    include Feed
    include Sink

    def initialize(*args)
      @inflate = Zlib::Inflate.new(*args)
    end

    def process(data = nil)
      if data.nil?
        super(@inflate.finish)
        super
      else
        super(@inflate.inflate(data))
      end
    end

  end


  class GzipCompressor

    include Feed
    include Sink

    def initialize(*args)
      @args = args
    end

    def process(data = nil)
      data.nil? ? @compressor.finish : @compressor.write(data)
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


  class GzipDecompressor

    include Feed
    include Sink

    def initialize(*args)
      @args = args
    end

    def process(data = nil)
      @data = data
      @decompressor = Zlib::GzipReader.new(self, *@args) if @decompressor.nil?
      super(@decompressor.read)
    end

    def read(count)
      @data
    end

    def process!
      super
    ensure
      @decompressor.close unless @decompressor.nil?
    end
  end


end