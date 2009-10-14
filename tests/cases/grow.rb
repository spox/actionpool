class GrowPoolTest < Test::Unit::TestCase
    def setup
        @pool = ActionPool::Pool.new
    end
    def test_grow
        jobs = [].fill(lambda{}, 0..99)
        @pool.add_jobs(jobs)
        assert(@pool.size > 10)
    end
end