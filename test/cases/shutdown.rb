require 'actionpool'
require 'test/unit'

class ShutdownPoolTest < Test::Unit::TestCase
  def setup
    @pool = ActionPool::Pool.new
  end
  def teardown
    @pool.shutdown(true)
  end
  def test_close
    result = 0
    @pool << lambda{ result = 5 }
    sleep(0.01)
    assert(5, result)
    @pool.status :closed
    assert_raise(ActionPool::PoolClosed) do
      @pool << lambda{}
    end
    assert_raise(ActionPool::PoolClosed) do
      @pool.add_jobs [lambda{}, lambda{}]
    end
    @pool.shutdown(true)
  end
  def test_shutdown
    assert_equal(10, @pool.size)
    @pool.shutdown
    sleep(0.5)
    assert_equal(0, @pool.size)
    @pool.status :open
    @pool << lambda{ sleep }
    sleep(0.01)
    assert_equal(10, @pool.size)
    @pool.shutdown(true)
  end
end