require 'actionpool'
require 'test/unit'

class TimeoutPoolTest < Test::Unit::TestCase
  def setup
    @pool = ActionPool::Pool.new(pool_args: {size: 20})
  end
  def teardown
    @pool.shutdown
  end
  def test_actiontimeout
    @pool.action_timeout = 3
    stop = false
    output = []
    20.times do
      @pool.process do
        until(stop) do
          output << 1
          sleep(4)
        end
      end
    end
    sleep(2)
    assert_equal(20, output.size)
    sleep(2)
    assert_equal(20, output.size)
    stop = true
  end
end
