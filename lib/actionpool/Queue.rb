require 'thread'

module ActionPool
    # Adds a little bit extra functionality to the Queue class
    class Queue < ::Queue
        # Create a new Queue for the ActionPool::Pool
        def initialize
            super
            @wait = false
            @pause_guard = Splib::Monitor.new
            @empty_guard = Splib::Monitor.new
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
            @pause_guard.broadcast
        end
        # Check if queue needs to wait before returning
        def pop
            @pause_guard.wait_while{ @wait }
            o = super
            @empty_guard.broadcast if empty?
            return o
        end
        # Clear queue
        def clear
            super
            @empty_guard.broadcast
        end
        # Park a thread here until queue is empty
        def wait_empty
            @empty_guard.wait_while{ size > 0 }
        end
    end
end