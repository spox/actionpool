require 'actionpool'
require 'test/unit'

class TimeoutPoolTest < Test::Unit::TestCase
    def setup
        @pool = ActionPool::Pool.new
    end
    def teardown
        @pool.shutdown(true)
    end
    def test_actiontimeout
        @pool.action_timeout = 0.01
        assert_equal(10, @pool.size)
        stop = false
        @pool.add_jobs [].fill(lambda{loop{ 1+1 }}, 0, 20)
        ::Thread.pass
        assert(@pool.working > 10)
        stop = true
        sleep(0.5)
        assert(@pool.working == 0)
        @pool.shutdown(true)
    end
    def test_threadtimeout
        @pool.thread_timeout = 0.01
        assert_equal(10, @pool.size)
        lock = Mutex.new
        guard = ConditionVariable.new
        @pool.add_jobs [].fill(lambda{ lock.synchronize{ guard.wait(lock) } }, 0, 20)
        ::Thread.pass
        assert_equal(30, @pool.size)
        lock.synchronize{ guard.broadcast }
        ::Thread.pass
        sleep(0.1)
        assert(10, @pool.size)
        @pool.shutdown(true)
    end
end