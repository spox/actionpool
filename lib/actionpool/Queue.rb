require 'thread'

module ActionPool
    # Adds a little bit extra functionality to the Queue class
    class Queue < ::Queue
        # Create a new Queue for the ActionPool::Pool
        def initialize
            super
            @wait = false
            @pause_lock = Mutex.new
            @empty_lock = Mutex.new
            @pause_guard = ConditionVariable.new
            @empty_guard = ConditionVariable.new
        end
        # Stop the queue from returning results to requesting
        # threads. Threads will wait for results until signalled
        def pause
            @pause_lock.synchronize{@wait = true}
        end
        # Allow the queue to return results. Any threads waiting
        # will have results given to them.
        def unpause
            @pause_lock.synchronize do
                @wait = false
                @pause_guard.broadcast
            end
        end
        # Check if queue needs to wait before returning
        def pop
            if(@wait)
                @pause_lock.synchronize do
                    @pause_guard.wait(@pause_lock)
                end
            end
            o = super
            if(empty?)
                @empty_lock.synchronize do
                    @empty_guard.broadcast
                end
            end
            return o
        end
        # Clear queue
        def clear
            super
            @empty_lock.synchronize do
                @empty_guard.broadcast
            end
        end
        # Park a thread here until queue is empty
        def wait_empty
            @empty_lock.synchronize do
                @empty_guard.wait(@empty_lock) if size > 0
            end
        end
    end
end