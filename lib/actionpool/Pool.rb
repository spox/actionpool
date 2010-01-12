require 'actionpool/Thread'
require 'actionpool/Queue'
require 'logger'
require 'thread'

module ActionPool
    # Raised when pool is closed
    class PoolClosed < StandardError
    end
    class Pool

        # :min_threads:: minimum number of threads in pool
        # :max_threads:: maximum number of threads in pool
        # :t_to:: thread timeout waiting for action to process
        # :a_to:: maximum time action may be worked on before aborting
        # :logger:: logger to print logging messages to
        # Creates a new pool
        def initialize(args={})
            raise ArgumentError.new('Hash required for initialization') unless args.is_a?(Hash)
            @logger = args[:logger] && args[:logger].is_a?(Logger) ? args[:logger] : Logger.new(nil)
            @queue = ActionPool::Queue.new
            @threads = []
            @lock = Splib::Monitor.new
            @thread_timeout = args[:t_to] ? args[:t_to] : 0
            @action_timeout = args[:a_to] ? args[:a_to] : 0
            @max_threads = args[:max_threads] ? args[:max_threads] : 100
            @min_threads = args[:min_threads] ? args[:min_threads] : 10
            @min_threads = @max_threads if @max_threads < @min_threads
            @respond_to = args[:respond_thread] || ::Thread.current
            @open = true
            fill_pool
        end

        # Pool is closed
        def pool_closed?
            !@open
        end

        # Pool is open
        def pool_open?
            @open
        end

        # arg:: :open or :closed
        # Set pool status
        def status(arg)
            @open = arg == :open
            fill_pool if @open
        end

        # args::    :force forces a new thread. 
        #           :nowait will create a thread if threads are waiting
        # Create a new thread for pool.
        # Returns newly created thread or nil if pool is at maximum size
        def create_thread(*args)
            return if pool_closed?
            thread = nil
            @lock.synchronize do
                if(((size == working || args.include?(:nowait)) && @threads.size < @max_threads) || args.include?(:force))
                    thread = ActionPool::Thread.new(:pool => self, :respond_thread => @respond_to, :a_timeout => @action_timeout,
                        :t_timeout => @thread_timeout, :logger => @logger, :autostart => false)
                    @threads << thread
                end
            end
            thread.start if thread
            thread
        end

        # Fills the pool with the minimum number of threads
        # Returns array of created threads
        def fill_pool
            threads = []
            if(@open)
                @lock.synchronize do
                    required = min - size
                    if(required > 0)
                        required.times do
                            thread = ActionPool::Thread.new(:pool => self, :respond_thread => @respond_to,
                                :a_timeout => @action_timeout, :t_timeout => @thread_timeout, :logger => @logger,
                                :autostart => false)
                            @threads << thread
                            threads << thread
                        end
                    end
                end
            end
            threads.each{|t|t.start}
            threads
        end

        # force:: force immediate stop
        # Stop the pool
        def shutdown(force=false)
            status(:closed)
            args = []
            args.push(:force) if force
            @logger.info("Pool is now shutting down #{force ? 'using force' : ''}")
            @queue.clear if force
            @queue.wait_empty
            while(t = @threads.pop) do
                t.stop(*args)
            end
            unless(force)
                flush
                @threads.each{|t|t.join}
            end
            nil
        end

        # action:: proc to be executed or array of [proc, [*args]]
        # Add a new proc/lambda to be executed (alias for queue)
        def <<(action)
            case action
                when Proc
                    queue(action)
                when Array
                    raise ArgumentError.new('Actions to be processed by the pool must be a proc/lambda or [proc/lambda, [*args]]') unless action.size == 2 and action[0].is_a?(Proc) and action[1].is_a?(Array)
                    queue(action[0], action[1])
                else
                    raise ArgumentError.new('Actions to be processed by the pool must be a proc/lambda or [proc/lambda, [*args]]')
            end
            nil
        end

        # action:: proc to be executed
        # Add a new proc/lambda to be executed
        def queue(action, *args)
            raise PoolClosed.new("Pool #{self} is currently closed") if pool_closed?
            raise ArgumentError.new('Expecting block') unless action.is_a?(Proc)
            @queue << [action, args]
            ::Thread.pass
            create_thread
        end

        # jobs:: Array of proc/lambdas
        # Will queue a list of jobs into the pool
        def add_jobs(jobs)
            raise PoolClosed.new("Pool #{self} is currently closed") if pool_closed?
            raise ArgumentError.new("Expecting an array but received: #{jobs.class}") unless jobs.is_a?(Array)
            @queue.pause
            begin
                jobs.each do |job|
                    case job
                    when Proc
                        @queue << [job, []]
                    when Array
                        raise ArgumentError.new('Jobs to be processed by the pool must be a proc/lambda or [proc/lambda, [*args]]') unless job.size == 2 and job[0].is_a?(Proc) and job[1].is_a?(Array)
                        @queue << [job.shift, job]
                    else
                        raise ArgumentError.new('Jobs to be processed by the pool must be a proc/lambda or [proc/lambda, [*args]]')
                    end
                end
            ensure
                num = jobs.size - @threads.select{|t|t.waiting?}.size
                num.times{ create_thread(:nowait) } if num > 0
                @queue.unpause
            end
            true
        end

        # block:: block to process
        # Adds a block to be processed
        def process(*args, &block)
            queue(block, *args)
            nil
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
            @min_threads = m if m < @min_threads
            resize if m < size
            m
        end

        # m:: new min
        # Set minimum number of threads
        def min=(m)
            m = m.to_i
            raise ArgumentError.new("Minimum value must be greater than 0 and less than or equal to maximum (#{max})") unless m > 0 && m <= max
            @min_threads = m
            m
        end

        # t:: ActionPool::Thread to remove
        # Removes a thread from the pool
        def remove(t)
            raise ArgumentError.new('Expecting an ActionPool::Thread object') unless t.is_a?(ActionPool::Thread)
            t.stop
            del = @threads.include?(t)
            @threads.delete(t) if del
            fill_pool
            del
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
            t = t.to_f
            raise ArgumentError.new('Value must be greater than zero or nil') unless t >= 0
            @thread_timeout = t
            @threads.each{|thread|thread.thread_timeout = t}
            t
        end

        # t:: timeout in seconds (nil for infinte)
        # Set maximum allowed time thread may work
        # on a given action
        def action_timeout=(t)
            t = t.to_f
            raise ArgumentError.new('Value must be greater than zero or nil') unless t >= 0
            @action_timeout = t
            @threads.each{|thread|thread.action_timeout = t}
            t
        end

        # Returns the next action to be processed
        def action
            @queue.pop
        end

        # Number of actions in the queue
        def action_size
            @queue.size
        end

        # Flush the thread pool. Mainly used for forcibly resizing
        # the pool if existing threads have a long thread life waiting
        # for input.
        def flush
            mon = Splib::Monitor.new
            @threads.size.times{ queue{ mon.wait } }
            @queue.wait_empty
            sleep(0.01)
            mon.broadcast
        end

        # Returns current number of threads in the pool working
        def working
            @threads.select{|t|t.running?}.size
        end

        def thread_stats
            @threads.map{|t|[t.object_id,t.status]}
        end

        private

        # Resize the pool
        def resize
            @logger.info("Pool is being resized to stated maximum: #{max}")
            until(size <= max) do
                t = nil
                t = @threads.find{|t|t.waiting?}
                t = @threads.shift unless t
                t.stop
            end
            flush
            nil
        end
    end
end