require 'actionpool'
require 'test/unit'

class GeneralPoolTest < Test::Unit::TestCase
    def setup
        @pool = ActionPool::Pool.new
    end
    def teardown
        @pool.shutdown(true)
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
        @pool.status :open
        a = 0
        jobs = [].fill(run,0,100)
        @pool.add_jobs(jobs)
        @pool.shutdown
        sleep(0.01)
        assert_equal(100, a)
        @pool.shutdown(true)
    end
    def test_args
        @pool.status :open
        output = nil
        @pool << [lambda{|x| output = x}, [2]]
        assert(2, output)
        output = nil
        @pool.add_jobs([[lambda{|x| output = x}, [3]]])
        assert(3, output)
        output = nil
        @pool << [lambda{|x,y| output = x+y}, [1,2]]
        assert(3, output)
        output = nil
        arr = []
        @pool.add_jobs([[lambda{|x,y| arr << x + y}, [1,1]], [lambda{|x| arr << x}, [3]]])
        ::Thread.pass
        sleep(0.01)
        assert(arr.include?(2))
        assert(arr.include?(3))
        arr.clear
        @pool << [lambda{|x,y| arr = [x,y]}, ['test', [1,2]]]
        sleep(0.01)
        assert_equal('test', arr[0])
        assert(arr[1].is_a?(Array))
        @pool.shutdown(true)
    end
end