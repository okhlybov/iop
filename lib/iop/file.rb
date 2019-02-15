require 'iop'


module IOP


  class IOReader

    include Feed

    def initialize(io, offset: nil, count: nil)
      @io = io
      @offset = offset
      @count = count
      @chunk_size = 1024 ** 2
      @chunk_size = count unless count.nil? || count > @chunk_size
    end

    def process!
      left = @count
      @io.seek(@offset) unless @offset.nil?
      data = RUBY_VERSION >= '2.4' ? String.new(capacity: @chunk_size) : String.new # Ruby 2.4+
      while true
        chunk_size = @count.nil? || left > @chunk_size ? @chunk_size : left
        if chunk_size.zero?
          break
        else
          result = @io.read(chunk_size, data)
          if result.nil?
            break
          else
            process(data)
            unless left.nil?
              left -= data.size
              raise EOFError, 'premature EOF encountered' if left < 0
            end
          end
        end
      end
      process
    end

  end


  class FileReader < IOReader

    def initialize(file, mode: 'rb', offset: nil, count: nil)
      super(File.new(file, mode), offset: offset, count: count)
    end

    def process!
      super
    ensure
      @io.close
    end

  end


  class IOWriter

    include Sink

    def initialize(io)
      @io = io
    end

    def process(data)
      @io.write(data)
    end

  end


  class FileWriter < IOWriter

    def initialize(file, mode: 'wb')
      super(File.new(file, mode))
    end

    def process!
      super
    ensure
      @io.close
    end

  end


end