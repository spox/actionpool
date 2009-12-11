require 'actionpool'
require 'test/unit'

class GrowPoolTest < Test::Unit::TestCase
    def setup
        @pool = ActionPool::Pool.new
    end
    def teardown
        @pool.shutdown(true)
    end
    def test_grow
        jobs = [].fill(lambda{sleep}, 0..20)
        @pool.add_jobs(jobs)
        Thread.pass
        assert(@pool.size > 10)
        @pool.shutdown(true)
    end
    def test_max
        @pool.create_thread(:force) until @pool.size > @pool.max
        assert(@pool.create_thread.nil?)
        assert(!@pool.create_thread(:force).nil?)
        @pool.shutdown(true)
    end
end