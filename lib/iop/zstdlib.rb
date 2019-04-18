require 'iop'
require 'zstdlib'


module IOP


  #
  # Filter class to perform data compression with Zstandard algorithm.
  #
  # This class produces valid _.zst_ files.
  #
  # ### Use case: compress a string and store it to .zst file.
  #
  #     require 'iop/file'
  #     require 'iop/string'
  #     require 'iop/zstdlib'
  #     ( IOP::StringSplitter.new('Hello IOP') | IOP::ZstdCompressor.new(Zstdlib::BEST_COMPRESSION) | IOP::FileWriter.new('hello.zst') ).process!
  #
  # @note this class depends on external +zstdlib+ gem.
  # @since 0.1
  #
  class ZstdCompressor

    include Feed
    include Sink

    # Creates class instance.
    # @param args [Array] arguments passed to +Zstdlib::Deflate+ constructor
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


  #
  # Filter class to perform Gzip data compression.
  #
  # This class is an adapter for the standard Ruby +Zlib::GzipWriter+ class.
  #
  # This class can decompress _.zst_ files.
  #
  # ### Use case: decompress a .zst file and compute MD5 hash sum of uncompressed data.
  #
  #     require 'iop/file'
  #     require 'iop/digest'
  #     require 'iop/zstdlib'
  #     ( IOP::FileReader.new('hello.zst') | IOP::ZstdDecompressor.new | (d = IOP::DigestComputer.new(Digest::MD5.new)) ).process!
  #     puts d.digest.hexdigest
  #
  # @note this class depends on external +zstdlib+ gem.
  # @since 0.1
  #
  class ZstdDecompressor

    include Feed
    include Sink

    # Creates class instance.
    # @param args [Array] arguments passed to +Zstdlib::Inflate+ constructor
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