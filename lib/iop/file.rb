require 'iop'


module IOP


  class IOReader

    include Feed

    def initialize(io, size: nil, offset: nil, block_size: DefaultBlockSize)
      @io = io
      @offset = offset
      @left = @size = size
      @block_size = size.nil? || size > block_size ? block_size : size
    end

    def process!
      @io.seek(@offset) unless @offset.nil?
      data = IOP.allocate_string(@block_size)
      loop do
        read_size = @size.nil? ? @block_size : min(@left, @block_size)
        if read_size.zero?
          break
        else
          if @io.read(read_size, data).nil?
            break
          else
            process(data)
            unless @left.nil?
              @left -= data.size
              raise EOFError, 'premature EOF encountered' if @left < 0
            end
          end
        end
      end
      process
    end

  end


  class FileReader < IOReader

    def initialize(file, mode: 'rb', offset: nil, count: nil)
      super(nil, offset: offset, size: count)
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

    def initialize(io, block_size: DefaultBlockSize)
      @io = io
      @block_size = block_size
    end

    private def next_data
      @io.read(@block_size)
    end

  end


end