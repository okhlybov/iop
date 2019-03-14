require 'test/unit'

require 'stringio'
require 'iop/file'
require 'iop/string'

class IOTest < Test::Unit::TestCase

  include IOP

  def test_iosegmentreader_small
    s = '0123456789'
    (1..s.size-1).each do |b|
      (1..11).each do |i|
        m = StringMerger.new
        r = IOSegmentReader.new(StringIO.open(s), block_size: i)
        (r.read!(b) | m).process!
        (r.read!(s.size-b) | m).process!
        assert_equal s, m.to_s
      end
    end
  end

end