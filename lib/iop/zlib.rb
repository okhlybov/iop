require 'iop'
require 'zlib'


module IOP


  #
  # Filter class to perform data compression with Zlib algorithm.
  #
  # This class is an adapter for the standard Ruby +Zlib::Deflate+ class.
  #
  # Note that this class does not produce valid _.gz_ files - use {GzipCompressor} for this purpose.
  #
  # ### Use case: compress a string.
  #
  #     require 'iop/zlib'
  #     require 'iop/string'
  #     ( IOP::StringSplitter.new('Hello IOP') | IOP::ZlibCompressor.new | (s = IOP::StringMerger.new) ).process!
  #     puts s.to_s
  #
  # @since 0.1
  #
  class ZlibCompressor

    include Feed
    include Sink

    # Creates class instance.
    #
    # @param args [Array] arguments passed to +Zlib::Deflate+ constructor
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
      begin
        super
      ensure
        @deflate.close
      end
    end
  end


  #
  # Filter class to perform data decompression with Zlib algorithm.
  #
  # This class is an adapter for the standard Ruby +Zlib::Inflate+ class.
  #
  # Note that this class can not decompress _.gz_ files - use {GzipDecompressor} for this purpose.
  #
  # ### Use case: decompress a Zlib-compressed part of a file skipping a header and compute MD5 hash sum of the uncompressed data.
  #
  #     require 'iop/zlib'
  #     require 'iop/file'
  #     require 'iop/digest'
  #     ( IOP::FileReader.new('input.dat', offset: 16) | IOP::ZlibDecompressor.new | (d = IOP::DigestComputer.new(Digest::MD5.new)) ).process!
  #     puts d.digest.hexdigest
  #
  # @since 0.1
  #
  class ZlibDecompressor

    include Feed
    include Sink

    # Creates class instance.
    #
    # @param args [Array] arguments passed to +Zlib::Inflate+ constructor
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
      begin
        super
      ensure
        @inflate.close
      end
    end
  end


  #
  # Filter class to perform Gzip data compression.
  #
  # This class is an adapter for the standard Ruby +Zlib::GzipWriter+ class.
  #
  # This class produces valid _.gz_ files.
  #
  # ### Use case: compress a string and store it to .gz file.
  #
  #     require 'iop/zlib'
  #     require 'iop/file'
  #     require 'iop/string'
  #     ( IOP::StringSplitter.new('Hello IOP') | IOP::GzipCompressor.new | IOP::FileWriter.new('hello.gz') ).process!
  #
  # @since 0.1
  #
  class GzipCompressor

    include Feed
    include Sink

    # Creates class instance.
    #
    # @param args [Array] arguments passed to +Zlib::GzipWriter+ constructor
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


  #
  # Filter class to perform Gzip data compression.
  #
  # This class is an adapter for the standard Ruby +Zlib::GzipWriter+ class.
  #
  # This class can decompress _.gz_ files.
  #
  # ### Use case: decompress a .gz file and compute MD5 hash sum of uncompressed data.
  #
  #     require 'iop/zlib'
  #     require 'iop/file'
  #     require 'iop/digest'
  #     ( IOP::FileReader.new('hello.gz') | IOP::GzipDecompressor.new | (d = IOP::DigestComputer.new(Digest::MD5.new)) ).process!
  #     puts d.digest.hexdigest
  #
  # @since 0.1
  #
  class GzipDecompressor < ZlibDecompressor
    def initialize
      super(16)
    end
  end


end