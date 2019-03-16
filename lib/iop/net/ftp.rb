require 'iop'
require 'net/ftp'


# @private
class Net::FTP
  public :transfercmd, :voidresp
end


module IOP


  # @private
  module FTP

    def initialize(ftp, file, size: nil, offset: nil, block_size: DEFAULT_BLOCK_SIZE, **options)
      @block_size = size.nil? ? block_size : IOP.min(size, block_size)
      @left = @size = size
      @options = options
      @offset = offset
      @file = file
      @ftp = ftp
    end

    def setup
      if @ftp.is_a?(String)
        @ftp = Net::FTP.open(@ftp, @options)
        @managed = true
        @ftp.login
      end
      unless @offset.nil?
        # Override resume status when offset is specified remembering current value
        @resume = @ftp.resume
        @ftp.resume = true
      end
    end

    def cleanup
      # Revert resume status if previously overridden
      @ftp.resume = @resume unless @resume.nil?
      @ftp.close if @managed
    end

    def transfercmd(cmd, offset = nil)
      @ftp.transfercmd(cmd, offset)
    end

    def voidresp
      @ftp.voidresp
    end

  end


  class FTPFileReader

    include Feed
    include FTP

    def process!
      setup
      begin
        # FTP logic taken from Net::FTP#retrbinary
        @io = transfercmd('RETR ' << @file, @offset)
        begin
          loop do
            read_size = @size.nil? ? @block_size : IOP.min(@left, @block_size)
            break if read_size.zero?
            data = @io.read(read_size)
            if data.nil?
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
              process(data) unless data.size.zero?
            end
          end
          process
          @io.shutdown(Socket::SHUT_WR)
          @io.read_timeout = 1
          @io.read
        ensure
          @io.close
        end
        voidresp
      ensure
        cleanup
      end
    end

  end



  class FTPFileWriter

    include Sink
    include FTP

    def process!
      setup
      begin
        # FTP logic taken from Net::FTP#storbinary
        @io = transfercmd('STOR ' << @file)
        begin
          super
        ensure
          @io.close
        end
        voidresp
      ensure
        cleanup
      end
    end

    def process(data = nil)
      @io.write(data) unless data.nil?
    end

  end


end