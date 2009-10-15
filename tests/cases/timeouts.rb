class TimeoutPoolTest < Test::Unit::TestCase
    def setup
        @pool = ActionPool::Pool.new
    end
    def test_threadtimeout
        @pool.thread_timeout = 1
        assert_equal(10, @pool.size)
        20.times{ @pool << lambda{ sleep(0.01) } }
        assert(@pool.size > 10)
        sleep(1.1)
        assert_equal(10, @pool.size)
    end
end