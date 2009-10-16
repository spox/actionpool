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
            @elock = Mutex.new
            @eguard = ConditionVariable.new
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
            @lock.synchronize{ @guard.broadcast }
        end
        # Check if queue needs to wait before returning
        def pop
            @lock.synchronize{ @guard.wait(@lock) } if @wait
            o = super
            @elock.synchronize{ @eguard.broadcast } if empty?
            return o
        end
        # Park a thread here until queue is empty
        def wait_empty
            @elock.synchronize{ @eguard.wait(@elock) } if size > 0
        end
    end
end