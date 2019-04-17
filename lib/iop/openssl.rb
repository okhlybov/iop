require 'iop'
require 'openssl'


module IOP


  # Default cipher ID for OpenSSL adapters.
  DEFAULT_OPENSSL_CIPHER = 'AES-256-CBC'.freeze


  #
  # Filter class to perform encryption with a symmetric key algorithm (ciphering) of the data passed through.
  #
  # The class is an adaptor for +OpenSSL::Cipher+ & compatible classes.
  #
  # ### Use case: generate 1024 bytes of random data encrypt is with default cipher algorithm and generated key & initial vector.
  #
  #     require 'iop/openssl'
  #     require 'iop/securerandom'
  #     ( IOP::SecureRandomGenerator.new(1024) | (c = IOP::CipherEncryptor.new) ).process!
  #     puts c.key
  #
  # @since 0.1
  #
  class CipherEncryptor

    include Feed
    include Sink

    # Returns initial vector (IV) for encryption session.
    attr_reader :iv

    # Returns encryption key.
    attr_reader :key

    # Creates class instance.
    #
    # _cipher_ can be either a +String+ or +OpenSSL::Cipher+ instance.
    # If it is a string, a corresponding +OpenSSL::Cipher+ instance will be created.
    #
    # If _key_ is +nil+, a new key will be generated in secure manner which can be accessed later with {#key} method.
    #
    # If _iv_ is +nil+, a new initial vector will be generated in secure manner which can be accessed later with {#iv} method.
    # If _iv_ is +nil+ the generated initial vector will be injected into the downstream data preceding the encrypted data itself.
    #
    # Note that key and initial vector are both cipher-dependent. Refer to +OpenSSL::Cipher+ documentation for more information.
    #
    # @param cipher [String, OpenSSL::Cipher] cipher used for encryption
    # @param key [String] string representing an encryption key or +nil+
    # @param iv [String] string representing an initial vector or +nil+
    def initialize(cipher = DEFAULT_OPENSSL_CIPHER, key: nil, iv: nil)
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


  #
  # Filter class to perform decryption with a symmetric key algorithm (ciphering) of the data passed through.
  #
  # The class is an adaptor for +OpenSSL::Cipher+ & compatible classes.
  #
  # ### Use case: decrypt a file with default algorithm and embedded initial vector.
  #
  #     require 'iop/file'
  #     require 'iop/openssl'
  #     ( IOP::FileReader.new('input.aes') | IOP::CipherDecryptor.new(key: my_secret_key) | (s = IOP::StringMerger.new) ).process!
  #     puts s.to_s
  #
  # @since 0.1
  #
  class CipherDecryptor

    include Feed
    include Sink

    # Returns initial vector (IV) for decryption session.
    attr_reader :iv

    # Returns decryption key.
    attr_reader :key

    # Creates class instance.
    #
    # _cipher_ can be either a +String+ or +OpenSSL::Cipher+ instance.
    # If it is a string, a corresponding +OpenSSL::Cipher+ instance will be created.
    #
    # If _iv_ is +nil+, the initial vector will be obtained from the upstream data. Refer to {CipherEncryptor#initialize} for details.
    #
    # @param cipher [String, OpenSSL::Cipher] cipher used for decryption
    # @param key [String] string representing an encryption key
    # @param iv [String] string representing an initial vector or +nil+
    def initialize(cipher = DEFAULT_OPENSSL_CIPHER, key:, iv: nil)
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