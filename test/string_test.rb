require 'test/unit'

require 'iop/string'

class StringTest < Test::Unit::TestCase

  include IOP

  def test_small
    t = '123456789'
    (1..10).each do |i|
      (StringSplitter.new(t, block_size: i) | (s = StringMerger.new)).process!
      assert_equal t, s.to_s
    end
  end

end