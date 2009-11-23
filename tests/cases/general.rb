require 'actionpool'
require 'test/unit'

class GeneralPoolTest < Test::Unit::TestCase
    def setup
        @pool = ActionPool::Pool.new
    end
    def test_numbers
        assert_equal(10, @pool.size)
        assert_equal(10, @pool.min)
        assert_equal(100, @pool.max)
        assert_equal(0, @pool.action_timeout)
        assert_equal(0, @pool.thread_timeout)
        assert_equal(0, @pool.action_size)
    end
    def test_output
        a = 0
        lock = Mutex.new
        run = lambda{ lock.synchronize{ a += 1 } }
        100.times{ @pool << run }
        @pool.shutdown
        assert_equal(100, a)
        a = 0
        jobs = [].fill(run,0,100)
        @pool.add_jobs(jobs)
        @pool.shutdown
        assert_equal(100, a)
        @pool.shutdown(true)
    end
    def test_args
        output = nil
        @pool << [lambda{|x| output = x}, [2]]
        assert(2, output)
        @pool.add_jobs([[lambda{|x| output = x}, [3]]])
        assert(3, output)
        @pool << [lambda{|x,y| output = x+y}, [1,2]]
        assert(3, output)
        output = []
        @pool.add_jobs([[lambda{|x,y| output << x + y}, [1,1]], [lambda{|x| output << x}, [3]]])
        assert(output.include?(2))
        assert(output.include?(3))
        @pool.shutdown(true)
    end
end