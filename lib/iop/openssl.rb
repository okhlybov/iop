require 'iop'
require 'openssl'


module IOP


  # @private
  OpenSSLDefaultCipher = 'AES-256-CBC'.freeze


  class CipherEncryptor

    include Feed
    include Sink

    attr_reader :iv, :key

    def initialize(cipher = OpenSSLDefaultCipher, key: nil, iv: nil)
      @cipher = cipher.is_a?(String) ? OpenSSL::Cipher.new(cipher) : cipher
      @cipher.encrypt
      @key = key.nil? ? @cipher.random_key : @cipher.key = key
      @iv = if iv.nil?
              @embed_iv = true
              @cipher.random_iv
            else
              @cipher.iv = iv
            end
    end

    def process(data = nil)
      unless @continue
        @continue = true
        super(iv) if @embed_iv
        @buffer = IOP.allocate_string(data.size)
      end
      if data.nil?
        super(@cipher.final)
        super
      else
        super(@cipher.update(data, @buffer)) unless data.size.zero?
      end
    end

  end


  class CipherDecryptor

    include Feed
    include Sink

    attr_reader :iv, :key

    def initialize(cipher = OpenSSLDefaultCipher, key:, iv: nil)
      @cipher = cipher.is_a?(String) ? OpenSSL::Cipher.new(cipher) : cipher
      @cipher.decrypt
      @cipher.key = @key = key
      @cipher.iv = @iv = iv unless iv.nil?
    end

    def process(data = nil)
      unless @continue
        @continue = true
        @buffer = IOP.allocate_string(data.size)
        if iv.nil?
          @cipher.iv = @iv = data[0, @cipher.iv_len]
          data = data[@cipher.iv_len..-1]
        end
      end
      if data.nil?
        super(@cipher.final)
        super
      else
        super(@cipher.update(data, @buffer)) unless data.size.zero?
      end
    end

  end


end