require 'iop'


module IOP


  #
  # Feed class to read data from external +IO+ stream and send it in blocks downstream.
  #
  # Contrary to {FileReader}, this class does not manage attached +IO+ instance, e.g.
  # it makes no attempt to close it after processing.
  #
  # ### Use case: sequential read of two 1024-byte blocks from the same +IO+ stream.
  #
  #     require 'iop/file'
  #     require 'iop/string'
  #     io = File.new('input.dat', 'rb')
  #     begin
  #       ( IOP::IOReader.new(io, size: 1024) | (first = IOP::StringMerger.new) ).process!
  #       ( IOP::IOReader.new(io, size: 1024, offset: 1024) | (second = IOP::StringMerger.new) ).process!
  #     ensure
  #       io.close
  #     end
  #     puts first.to_s
  #     puts second.to_s
  #
  # @since 0.1
  #
  class IOReader < RandomAccessReader

    # Creates class instance.
    #
    # @param io [IO] +IO+ instance to read data from
    #
    # @param options [Hash] keyword arguments passed to {RandomAccessReader} constructor
    def initialize(io, **options)
      super(**options)
      @io = io
    end

    private

    def seek!() @io.seek(@offset) end

    def read!(read_size, data) @io.read(read_size, data) end

  end


  #
  # Feed class to read data from local file and send it in blocks downstream.
  #
  # Contrary to {IOReader}, this class manages underlying +IO+ instance in order to close it when the process is finished
  # even if exception is risen.
  #
  # ### Use case: compute MD5 hash sum of the first 1024 bytes of a local file.
  #     require 'iop/file'
  #     require 'iop/digest'
  #     ( IOP::FileReader.new('input.dat', size: 1024) | (d = IOP::DigestComputer.new(Digest::MD5.new)) ).process!
  #     puts d.digest.hexdigest
  #
  # @since 0.1
  #
  class FileReader < IOReader

    # Creates class instance.
    #
    # @param file [String] name of file to read from
    #
    # @param mode [String] open mode for the file; refer to {File} for details
    #
    # @param options [Hash] keyword parameters passed to {IOReader} constructor
    def initialize(file, mode: 'rb', **options)
      super(nil, **options)
      @file = file
      @mode = mode
    end

    def process!
      @io = File.new(@file, @mode)
      begin
        super
      ensure
        @io.close
      end
    end

  end


  #
  # Sink class to write received upstream data to external +IO+ stream.
  #
  # Contrary to {FileWriter}, this class does not manage attached +IO+ instance, e.g.
  # it makes no attempt to close it after processing.
  #
  # ### Use case: concatenate two files.
  #
  #     require 'iop/file'
  #     io = File.new('output.dat', 'wb')
  #     begin
  #       ( IOP::FileReader.new('file1.dat') | IOP::IOWriter.new(io) ).process!
  #       ( IOP::FileReader.new('file2.dat') | IOP::IOWriter.new(io) ).process!
  #     ensure
  #       io.close
  #     end
  #
  # @since 0.1
  #
  class IOWriter

    include Sink

    # Creates class instance.
    #
    # @param io [IO] +IO+ instance to write data to
    def initialize(io)
      @io = io
    end

    def process(data = nil)
      @io.write(data)
    end

  end


  #
  # Sink class to write received upstream data to a local file.
  #
  # Contrary to {IOWriter}, this class manages underlying +IO+ instance in order to close it when the process is finished
  # even if exception is risen.
  #
  # ### Use case: generate 1024 bytes of random data and write it to file.
  #
  #     require 'iop/file'
  #     require 'iop/securerandom'
  #     ( IOP::SecureRandomGenerator.new(1024) | IOP::FileWriter.new('random.dat') ).process!
  #
  # @since 0.1
  #
  class FileWriter < IOWriter

    # Creates class instance.
    #
    # @param file [String] name of file to write to
    #
    # @param mode [String] open mode for the file; refer to {File} for details
    def initialize(file, mode: 'wb')
      super(nil)
      @file = file
      @mode = mode
    end

    def process!
      @io = File.new(@file, @mode)
      begin
        super
      ensure
        @io.close
      end
    end

  end


  # @private
  class IOSegmentReader

    include BufferingFeed

    def initialize(io, block_size: DEFAULT_BLOCK_SIZE)
      @io = io
      @block_size = block_size
    end

    private def next_data
      @io.read(@block_size)
    end

  end


end