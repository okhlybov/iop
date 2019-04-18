require 'iop'
require 'net/ftp'


# @private
class Net::FTP
  public :transfercmd, :voidresp
end


module IOP


  # @private
  module FTPFile

    private

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

  #
  # Feed class to read file from FTP server.
  #
  # This class an adapter for the standard Ruby +Net::FTP+ class.
  #
  # ### Use case: retrieve file from FTP server and store it locally.
  #
  #     require 'iop/net/ftp'
  #     ( IOP::FTPFileReader.new('ftp.gnu.org', '/pub/README') | IOP::FileWriter.new('README') ).process!
  #
  # @since 0.1
  #
  class FTPFileReader

    include Feed
    include FTPFile

    # Creates class instance.
    #
    # @param ftp [String, Net::FTP] FTP server to connect to
    # @param file [String] file name to process
    # @param size [Integer] total number of bytes to read; +nil+ value instructs to read until end-of-data is reached
    # @param offset [Integer] offset in bytes from the stream start to seek to; +nil+ value means no seeking is performed
    # @param block_size [Integer] size of blocks to process data with
    # @param options [Hash] extra keyword parameters passed to +Net::FTP+ constructor
    #
    # _ftp_ can be either a +String+ of +Net::FTP+ instance.
    # If it is a string a corresponding +Net::FTP+ instance will be created with _options_ passed to its constructor.
    #
    # If _ftp_ is a string, a created FTP connection is managed, e.g. it is closed after the process is complete,
    # otherwise supplied object is left as is and no closing is performed.
    # This allows to reuse FTP connection for a sequence of operations.
    #
    # Refer to +Net::FTP+ documentation for available options.
    def initialize(ftp, file, size: nil, offset: nil, block_size: DEFAULT_BLOCK_SIZE, **options)
      @block_size = size.nil? ? block_size : IOP.min(size, block_size)
      @left = @size = size
      @options = options
      @offset = offset
      @file = file
      @ftp = ftp
    end

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



  #
  # Sink class to write file to FTP server.
  #
  # This class an adapter for the standard Ruby +Net::FTP+ class.
  #
  # ### Use case: store a number of files filled with random data to an FTP server reusing connection.
  #
  #     require 'iop/net/ftp'
  #     require 'iop/securerandom'
  #     ftp = Net::FTP.open('ftp.server', username: 'user')
  #     begin
  #       ftp.login
  #       (1..3).each do |i|
  #         ( IOP::SecureRandomGenerator.new(1024) | IOP::FTPFileWriter.new(ftp, "random#{i}.dat") ).process!
  #       end
  #     ensure
  #       ftp.close
  #     end
  #
  # @since 0.1
  #
  class FTPFileWriter

    include Sink
    include FTPFile

    # Creates class instance.
    #
    # @param ftp [String, Net::FTP] FTP server to connect to
    # @param file [String] file name to process
    # @param options [Hash] extra keyword parameters passed to +Net::FTP+ constructor
    #
    # _ftp_ can be either a +String+ of +Net::FTP+ instance.
    # If it is a string a corresponding +Net::FTP+ instance will be created with _options_ passed to its constructor.
    #
    # If _ftp_ is a string, a created FTP connection is managed, e.g. it is closed after the process is complete,
    # otherwise supplied object is left as is and no closing is performed.
    # This allows to reuse FTP connection for a sequence of operations.
    def initialize(ftp, file, **options)
      @options = options
      @file = file
      @ftp = ftp
    end

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