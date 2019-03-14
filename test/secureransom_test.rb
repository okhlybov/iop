require 'test/unit'

require 'iop/string'
require 'iop/securerandom'


class SecureRandomTest < Test::Unit::TestCase

  include IOP

  def test_securerandom
    (SecureRandomGenerator.new(size = 1024, block_size: 100) | (s = StringMerger.new)).process!
    assert_equal size, s.to_s.size
  end

end