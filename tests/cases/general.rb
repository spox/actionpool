class GeneralPoolTest < Test::Unit::TestCase
    def setup
        @pool = ActionPool::Pool.new
    end
    def test_numbers
        assert_equal(10, @pool.size)
        assert_equal(10, @pool.min)
        assert_equal(100, @pool.max)
        assert_nil(@pool.action_timeout)
        assert_equal(60, @pool.thread_timeout)
        assert_equal(0, @pool.action_size)
    end
end