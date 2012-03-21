require 'actionpool'
require 'test/unit'

class NoGrowPoolTest < Test::Unit::TestCase
  def setup
    @pool = ActionPool::Pool.new
  end
  def teardown
    @pool.shutdown(true)
  end
  def test_nogrow
    5.times{ @pool << lambda{} }
    assert_equal(10, @pool.size)
  end
end