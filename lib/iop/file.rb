require 'iop'


module IOP


  class IOReader

    include Feed

    def initialize(io, size: nil, offset: nil, block_size: DEFAULT_BLOCK_SIZE)
      @block_size = size.nil? ? block_size : IOP.min(size, block_size)
      @left = @size = size
      @offset = offset
      @io = io
    end

    def process!
      @io.seek(@offset) unless @offset.nil?
      data = IOP.allocate_string(@block_size)
      loop do
        read_size = @size.nil? ? @block_size : IOP.min(@left, @block_size)
        break if read_size.zero?
        if @io.read(read_size, data).nil?
          if @size.nil?
            break
          else
            raise EOFError, INSUFFICIENT_DATA
          end
        else
          unless @left.nil?
            @left -= data.size
            raise IOError, EXTRA_DATA if @left < 0
          end
        end
        process(data) unless data.size.zero?
      end
      process
    end

  end


  class FileReader < IOReader

    def initialize(file, mode: 'rb', offset: nil, size: nil)
      super(nil, offset: offset, size: size)
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


  class IOWriter

    include Sink

    def initialize(io)
      @io = io
    end

    def process(data = nil)
      @io.write(data)
    end

  end


  class FileWriter < IOWriter

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