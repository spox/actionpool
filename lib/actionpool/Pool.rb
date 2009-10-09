require 'actionpool/Thread'
require 'actionpool/LogHelper'
require 'thread'

module ActionPool
    class Pool

        # :min_threads:: minimum number of threads in pool
        # :max_threads:: maximum number of threads in pool
        # :t_to:: thread timeout waiting for action to process
        # :a_to:: maximum time action may be worked on before aborting
        # :logger:: logger to print logging messages to
        # Creates a new pool
        def initialize(args={})
            @logger = LogHelper.new(args[:logger] ? args[:logger] : nil)
            @queue = Queue.new
            @threads = []
            @lock = Mutex.new
            @thread_timeout = args[:t_to] ? args[:t_to] : 60
            @action_timeout = args[:a_to] ? args[:a_to] : nil
            @min_threads = args[:min_threads] ? args[:min_threads] : 10
            @max_threads = args[:max_threads] ? args[:max_threads] : 100
            @respond_to = ::Thread.current
            @min_threads.times{create_thread}
        end

        # force:: force creation of a new thread
        # Create a new thread for pool
        def create_thread(force=false)
            return nil unless @threads.size < @max_threads || force
            @logger.info('Pool is creating a new thread')
            pt = ActionPool::Thread.new(:pool => self, :respond_thread => @respond_to, :a_timeout => @action_timeout, :t_timeout => @thread_timeout, :logger => @logger)
            @threads << pt
            return pt
        end

        # force:: force immediate stop
        # Stop the pool
        def shutdown(force=false)
            @logger.info("Pool is now shutting down #{force ? 'using force' : ''}")
            @threads.each{|t|t.stop(force)}
            until(size < 1) do
                @queue << lambda{}
                sleep(0.1)
            end
        end

        # action:: proc to be executed
        # Add a new proc/lambda to be executed (alias for queue)
        def <<(action)
            queue(action)
        end

        # action:: proc to be executed
        # Add a new proc/lambda to be executed
        def queue(action)
            raise ArgumentError.new('Expecting block') unless action.is_a?(Proc)
            @queue << action
            start_thread if size > min
        end

        # block:: block to process
        # Adds a block to be processed
        def process(&block)
            queue(block)
        end

        # Current size of pool
        def size
            @threads.size
        end

        # Maximum allowed number of threads
        def max
            @max_threads
        end

        # Minimum allowed number of threads
        def min
            @min_threads
        end

        # m:: new max
        # Set maximum number of threads
        def max=(m)
            m = m.to_i
            raise ArgumentError.new('Maximum value must be greater than 0') unless m > 0
            @max_threads = m
        end

        # m:: new min
        # Set minimum number of threads
        def min=(m)
            m = m.to_i
            raise ArgumentError.new("Minimum value must be greater than 0 and less than or equal to maximum (#{max})") unless m > 0 && m <= max
            @min_threads = m
            resize if m < size
        end

        # t:: ActionPool::Thread to remove
        # Removes a thread from the pool
        def remove(t)
            @threads.delete(t)
        end

        # Maximum number of seconds a thread
        # is allowed to idle in the pool. 
        # (nil means thread life is infinite)
        def thread_timeout
            @thread_timeout
        end

        # Maximum number of seconds a thread
        # is allowed to work on a given action
        # (nil means thread is given unlimited
        # time to work on action)
        def action_timeout
            @action_timeout
        end

        # t:: timeout in seconds (nil for infinite)
        # Set maximum allowed time thead may idle in pool
        def thread_timeout=(t)
            t = to_i unless t.nil?
            raise ArgumentError.new('Value must be great than zero or nil') unless t.nil? || t > 0
            @thread_timeout = t
        end

        # t:: timeout in seconds (nil for infinte)
        # Set maximum allowed time thread may work
        # on a given action
        def action_timeout=(t)
            t = to_i unless t.nil?
            raise ArgumentError.new('Value must be great than zero or nil') unless t.nil? || t > 0
            @action_timeout = t
        end

        # Returns the next action to be processed
        def action
            @queue.pop
        end

        # Number of actions in the queue
        def action_size
            @queue.size
        end

        private
        
        def resize
            @logger.info("Pool is being resized to stated minimum: #{min}")
            size - min.times do
                t = @threads.shift
                t.stop
            end
        end
    end
end