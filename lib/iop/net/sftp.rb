require 'iop'
require 'net/sftp'


module IOP


  # @private
  module SFTPCommons

    private

    def setup
      if @sftp.is_a?(String)
        @sftp = Net::SFTP.start(@sftp, @options.delete(:username), **@options)
        @managed = true
      end
    end

    def cleanup
      if @managed
        ssh = @sftp.session
        @sftp.close_channel
        ssh.close
      end
    end

  end


  #
  # Feed class to read file from SFTP server.
  #
  # This class an adapter for +Net::SFTP::Session+ class.
  #
  # ### Use case: retrieve current user's _~/.profile_ file from SFTP server running on local machine and and compute its MD5 hash sum.
  #
  #     require 'iop/digest'
  #     require 'iop/net/sftp'
  #     ( IOP::SFTPFileReader.new('localhost', '.profile') | (d = IOP::DigestComputer.new(Digest::MD5.new)) ).process!
  #     puts d.digest.hexdigest
  #
  # @note this class depends on external +net-sftp+ gem.
  # @since 0.2
  #
  class SFTPFileReader < RandomAccessReader

    include Feed
    include SFTPCommons

    # Creates class instance.
    #
    # @param sftp [String, Net::SFTP::Session] SFTP server to connect to
    #
    # @param file [String] file name to process
    #
    # @param size [Integer] total number of bytes to read; +nil+ value instructs to read until end-of-data is reached
    #
    # @param offset [Integer] offset in bytes from the stream start to seek to; +nil+ value means no seeking is performed
    #
    # @param block_size [Integer] size of blocks to process data with
    #
    # @param options [Hash] extra keyword parameters passed to +Net::SFTP::Session+ constructor, such as username, password etc.
    #
    # _sftp_ can be either a +String+ of +Net::SFTP::Session+ instance.
    # If it is a string a corresponding +Net::SFTP::Session+ instance will be created with _options_ passed to its constructor.
    #
    # If _sftp_ is a string, a created SFTP session is managed, e.g. it is closed after the process is complete,
    # otherwise supplied object is left as is and no closing is performed.
    # This allows to reuse SFTP session for a sequence of operations.
    #
    # Refer to +Net::SFTP+ documentation for available options.
    def initialize(sftp, file, size: nil, offset: nil, block_size: DEFAULT_BLOCK_SIZE, **options)
      super(size: size, offset: offset, block_size: block_size)
      @options = options
      @file = file
      @sftp = sftp
    end

    def process!
      setup
      begin
        @io = @sftp.open!(@file, 'r')
        begin
          super
        ensure
          @sftp.close(@io)
        end
      ensure
        cleanup
      end
    end

    private

    def read!(read_size, buffer)
      data = @sftp.read!(@io, @offset ||= 0, read_size)
      @offset += data.size unless data.nil?
      data
    end

  end


  #
  # Sink class to write file to SFTP server.
  #
  # This class an adapter for +Net::SFTP::Session+ class.
  #
  # ### Use case: store a number of files filled with random data to remote SFTP server reusing session.
  #
  #     require 'iop/net/sftp'
  #     require 'iop/securerandom'
  #     sftp = Net::SFTP.start('sftp.server', username: 'user',  password: '123')
  #     begin
  #       (1..3).each do |i|
  #         ( IOP::SecureRandomGenerator.new(1024) | IOP::SFTPFileWriter.new(sftp, "random#{i}.dat") ).process!
  #       end
  #     ensure
  #       sftp.session.close
  #     end
  #
  # @note this class depends on external +net-sftp+ gem.
  # @since 0.2
  #
  class SFTPFileWriter

    include Sink
    include SFTPCommons

    # Creates class instance.
    #
    # @param sftp [String, Net::SFTP::Session] SFTP server to connect to
    #
    # @param file [String] file name to process
    #
    # @param options [Hash] extra keyword parameters passed to +Net::SFTP::Session+ constructor
    #
    # _sftp_ can be either a +String+ of +Net::SFTP::Session+ instance.
    # If it is a string a corresponding +Net::SFTP::Session+ instance will be created with _options_ passed to its constructor.
    #
    # If _sftp_ is a string, a created SFTP session is managed, e.g. it is closed after the process is complete,
    # otherwise supplied object is left as is and no closing is performed.
    # This allows to reuse SFTP session for a sequence of operations.
    def initialize(sftp, file, **options)
      @options = options
      @file = file
      @sftp = sftp
    end

    def process!
      setup
      begin
        @io = @sftp.open!(@file, 'w')
        @offset = 0
        begin
          super
        ensure
          @sftp.close(@io)
        end
      ensure
        cleanup
      end
    end

    def process(data = nil)
      unless data.nil?
        @sftp.write!(@io, @offset, data)
        @offset += data.size
      end
    end

  end


end