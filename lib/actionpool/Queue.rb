require 'thread'

# This is a stub so we don't have to load the
# actual PriorityQueue library unless we need it
module Splib
    class PriorityQueue
    end
end

module ActionPool
    class << self
        def enable_priority_q
            Splib.load :PriorityQueue
        end
    end
    class PQueue < Splib::PriorityQueue
        def initialize
            super
            @wait = false
            @pause_guard = Splib::Monitor.new
            @empty_guard = Splib::Monitor.new
            extend QueueMethods
        end
    end
    # Adds a little bit extra functionality to the Queue class
    class Queue < ::Queue
        def initialize
            super
            @wait = false
            @pause_guard = Splib::Monitor.new
            @empty_guard = Splib::Monitor.new
            extend QueueMethods
        end
    end
    module QueueMethods
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