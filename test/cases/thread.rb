require 'actionpool'
require 'test/unit'

class ThreadTest < Test::Unit::TestCase
    def setup
        @pool = ActionPool::Pool.new(:min_threads => 1, :max_threads => 1)
        @thread = ActionPool::Thread.new(:pool => @pool, :respond_thread => self, :t_timeout => 60, :a_timeout => 0)
    end
    def teardown
        @pool.shutdown(true)
    end
    def test_thread
        sleep(0.01)
        assert(@thread.waiting?)
        assert_equal(60, @thread.thread_timeout)
        assert_equal(0, @thread.action_timeout)
        assert(@thread.alive?)
        stop = false
        10.times{ @pool << lambda{ a = 0; a += 1 until stop || a > 9999999999 } }
        assert(!@thread.waiting?)
        @thread.stop(:force)
        sleep(0.01)
        assert(!@thread.alive?)
        stop = true
        @pool.shutdown(true)
    end
end