class TimeoutPoolTest < Test::Unit::TestCase
    def setup
        @pool = ActionPool::Pool.new
    end
    def test_threadtimeout
        @pool.thread_timeout = 0.01
        assert_equal(10, @pool.size)
        stop = false
        100.times{ @pool << lambda{ a = 0; a += 1 until stop || a > 9999999999 } }
        assert(@pool.size > 10)
        stop = true
        sleep(1)
        assert(@pool.size <= 10)
        @pool.shutdown(true)
    end
end