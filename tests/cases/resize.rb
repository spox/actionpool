require 'actionpool'
require 'test/unit'

class ResizePoolTest < Test::Unit::TestCase
    def setup
        @pool = ActionPool::Pool.new
    end
    def teardown
        @pool.shutdown(true)
    end
    def test_resize
        stop = false
        20.times{ @pool << lambda{ sleep } }
        Thread.pass
        sleep(0.1)
        assert(@pool.size > 10)
        stop = true
        @pool.shutdown(true)
        @pool.status :open
        @pool.max = 10
        assert_equal(10, @pool.max)
        stop = false
        20.times{ @pool << lambda{ a = 0; a += 1 until stop || a > 9999999999 } }
        assert_equal(10, @pool.size)
        stop = true
        @pool.shutdown(true)
        @pool.status :open
        @pool.max = 20
        stop = false
        30.times{ @pool << lambda{ a = 0; a += 1 until stop || a > 9999999999 } }
        stop = true
        assert(@pool.size > 10)
        @pool.shutdown(true)
    end
end