require 'actionpool'
require 'test/unit'

class QueueTest < Test::Unit::TestCase
  def setup
    @queue = ActionPool::Queue.new
  end
  def test_pop
    3.times{|i|@queue << i}
    3.times{|i|assert(i, @queue.pop)}
    assert(@queue.empty?)
  end
  def test_pause
    3.times{|i|@queue << i}
    @queue.pause
    output = []
    3.times{Thread.new{output << @queue.pop}}
    assert(output.empty?)
    assert_equal(3, @queue.size)
    @queue.unpause
    sleep(1)
    assert(@queue.empty?)
    assert_equal(3, output.size)
    3.times{|i|assert(output.include?(i))}
    @queue << 1
    output = nil
    Thread.new{@queue.wait_empty; output = true}
    assert_nil(output)
    @queue.pop
    Thread.pass
    sleep(0.01)
    assert(output)
  end
end