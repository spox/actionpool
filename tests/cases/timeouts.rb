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
        @pool.action_timeout = 0.25
        assert_equal(10, @pool.size)
        stop = false
        output = []
        20.times do
            @pool.process do
                until(stop) do
                    output << 1
                    sleep(0.1)
                end
            end
        end
        assert(@pool.working >= 10)
        assert_equal(20, output.size)
        sleep(0.11)
        stop = true
        sleep(0.1)
        assert_equal(0, @pool.working)
        assert_equal(40, output.size)
        @pool.shutdown(true)
    end
    def test_threadtimeout
        @pool.thread_timeout = 0.05
        assert_equal(10, @pool.size)
        t = [].fill(lambda{
                        begin
                            sleep(0.1)
                        rescue
                        end }, 0, 20)
        @pool.add_jobs(t)
        ::Thread.pass
        sleep(0.01)
        assert(@pool.size >= 20)
        ::Thread.pass
        sleep(0.1)
        assert(10, @pool.size)
        @pool.shutdown(true)
    end
end