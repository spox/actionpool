class ResizePoolTest < Test::Unit::TestCase
    def setup
        @pool = ActionPool::Pool.new
    end
    def test_resize
        500.times{ @pool << lambda{sleep(0.1)} }
        sleep(0.5)
        assert_equal(100, @pool.size)
        @pool.max = 10
        sleep(0.2) # allow some cleanup time
        assert_equal(10, @pool.max)
        assert_equal(10, @pool.size)
        500.times{ @pool << lambda{} }
        assert_equal(10, @pool.size)
        @pool.max = 20
        500.times{ @pool << lambda{sleep(0.01)} }
        assert_equal(20, @pool.size)
    end
end