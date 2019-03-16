require 'iop'
require 'net/ftp'


# @private
class Net::FTP
  public :transfercmd, :voidresp
end


module IOP


  # @private
  module FTP

    def initialize(ftp, file, block_size: DefaultBlockSize, **options)
      @block_size = block_size
      @options = options
      @file = file
      @ftp = ftp
    end

    def setup
      if @ftp.is_a?(String)
        @ftp = Net::FTP.open(@ftp, @options)
        @ftp.login
        @managed = true
      end
    end

    def cleanup
      @ftp.close if @managed
    end

    def transfercmd(cmd)
      @ftp.transfercmd(cmd)
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
        # Code based on Net::FTP#retrbinary
        @io = transfercmd('RETR ' << @file)
        begin
          loop do
            process(data = @io.read(@block_size))
            break if data.nil?
          end
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
        # Code based on Net::FTP#storbinary
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