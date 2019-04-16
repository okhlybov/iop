require 'test/unit'
require 'iop/digest'
require 'iop/file'
require 'openssl'

class DigestTest < Test::Unit::TestCase

  include IOP

  def test_digest
    ( FileReader.new(__FILE__) | DigestComputer.new(Digest::MD5.new) ).process!
  end

  def test_openssl_digest
    ( FileReader.new(__FILE__) | DigestComputer.new(OpenSSL::Digest::MD5.new) ).process!
  end

end