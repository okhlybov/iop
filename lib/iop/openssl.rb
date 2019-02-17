require 'iop'


module IOP


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
              @prepend_iv = true
              @cipher.random_iv
            else
              @cipher.iv = iv
            end
    end

    def process(data = nil)
      unless @continue
        super(iv)if @prepend_iv
        @continue = true
        @buffer = IOP.allocate_string(data.size)
      end
      super(data.nil? ? @cipher.final : @cipher.update(data, @buffer))
    end

  end


  class CipherDecryptor

    include Feed
    include Sink

    def initialize(cipher = OpenSSLDefaultCipher, key:, iv: nil)
      @cipher = cipher.is_a?(String) ? OpenSSL::Cipher.new(cipher) : cipher
      @cipher.decrypt
      @key = key.nil? ? @cipher.random_key : @cipher.key = key
      @iv = if iv.nil?
              @prepend_iv = true
              @cipher.random_iv
            else
              @cipher.iv = iv
            end
    end

  end


end