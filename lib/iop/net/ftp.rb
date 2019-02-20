require 'iop'
require 'net/ftp'


class Net::FTP

  def store_setup(file)
    @iop = transfercmd("STOR " + file)
  end

  def store_cleanup
    @iop.close
    voidresp
  end

  def store_rescue
    getresp
  end

end


module IOP


  module FtpFile

    def initialize(ftp, file, options = {})
      @options = options
      @file = file
      @ftp = ftp
      end

  private

    def setup
      if @ftp.is_a?(String)
        @ftp = Net::FTP.open(@ftp, @options)
        @managed = true
      end
    end

    def login
      @ftp.login if @managed
    end

    def cleanup
      @ftp.close if @managed
    end

  end


  class FtpFileReader

    include Feed
    include FtpFile

    def process!
      setup
      begin
        login
        @ftp.get(@file, nil) {|data| process(data)} # TODO partial read
        process
      ensure
        cleanup
      end
    end

  end


  class FtpFileWriter

    include Sink
    include FtpFile

    def process!
      setup
      begin
        login
        begin
          @io = @ftp.store_setup(@file)
          super
          @ftp.store_cleanup
        rescue Errno::EPIPE
          @ftp.store_rescue
          raise
        end
      ensure
        cleanup
      end
    end

    def process(data = nil)
      @io.write(data) unless data.nil?
    end

  end


end