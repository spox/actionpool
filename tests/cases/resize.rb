class ResizePoolTest < Test::Unit::TestCase
    def setup
        @pool = ActionPool::Pool.new
    end
    def test_resize
        stop = false
        50.times{ @pool << lambda{ a = 0; a += 1 until stop || a > 9999999999 } }
        assert(@pool.size > 10)
        stop = true
        @pool.max = 10
        assert_equal(10, @pool.max)
        assert_equal(10, @pool.size)
        stop = false
        50.times{ @pool << lambda{ a = 0; a += 1 until stop || a > 9999999999 } }
        assert_equal(10, @pool.size)
        stop = true
        @pool.max = 20
        stop = false
        50.times{ @pool << lambda{ a = 0; a += 1 until stop || a > 9999999999 } }
        assert_equal(20, @pool.size)
        stop = true
        @pool.shutdown(true)
    end
end