require 'timeout'

module ActionPool
  class QueueProcessor

    include Celluloid

    attr_accessor :process

    def initialize(pool)
      @process = true
      @pool = pool
      @queue = []
      @paused = false
      process_queue!
    end

    def <<(ary)
      @queue << ary
      signal :wakeup unless @paused
    end

    def process_queue
      while(@process)
        if(@queue.empty?)
          wait :wakeup
        else
          action = @queue.shift
          @pool.block_call!(action.first, *action.last)
        end
      end
    end

    def pause
      @paused = true
    end

    def unpause
      @paused = false
      signal :wakeup
    end

    def halt
      @process = false
      signal :wakeup
    end

  end
end
