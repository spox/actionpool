require 'thread'

module ActionPool
    # Adds a little bit extra functionality to the Queue class
    class Queue < ::Queue
        # Create a new Queue for the ActionPool::Pool
        def initialize
            super
            @wait = false
            @lock = Mutex.new
            @guard = ConditionVariable.new
        end
        # Stop the queue from returning results to requesting
        # threads. Threads will wait for results until signalled
        def pause
            @wait = true
        end
        # Allow the queue to return results. Any threads waiting
        # will have results given to them.
        def unpause
            @wait = false
            @lock.synchronize{ @guard.signal }
        end
        # Check if queue needs to wait before returning
        def pop
            val = super
            @lock.synchronize{ @guard.wait(@lock) } if @wait
            val
        end
    end
end