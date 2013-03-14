require 'actionpool'
require 'test/unit'

class GeneralPoolTest < Test::Unit::TestCase
  def setup
    @pool = ActionPool::Pool.new
  end

  def teardown
    @pool.shutdown
  end
  
  def test_args
    output = nil
    @pool << [lambda{|x| output = x}, [2]]
    sleep(0.5)
    assert_equal(2, output)
    output = nil
    @pool.add_jobs([[lambda{|x| output = x}, [3]]])
    sleep(0.1)
    assert_equal(3, output)
    output = nil
    @pool << [lambda{|x,y| output = x+y}, [1,2]]
    sleep(0.1)
    assert_equal(3, output)
    output = nil
    arr = []
    @pool.add_jobs([[lambda{|x,y| arr << x + y}, [1,1]], [lambda{|x| arr << x}, [3]]])
    sleep(0.1)
    assert(arr.include?(2))
    assert(arr.include?(3))
    arr.clear
    @pool << [lambda{|x,y| arr = [x,y]}, ['test', [1,2]]]
    sleep(0.01)
    assert_equal('test', arr[0])
    assert(arr[1].is_a?(Array))
  end
end
