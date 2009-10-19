require 'actionpool'
require 'test/unit'

class ShutdownPoolTest < Test::Unit::TestCase
    def setup
        @pool = ActionPool::Pool.new
    end
    def test_shutdown
        assert_equal(10, @pool.size)
        @pool.shutdown
        sleep(0.5)
        assert_equal(0, @pool.size)
        @pool << lambda{}
        assert_equal(10, @pool.size)
    end
end