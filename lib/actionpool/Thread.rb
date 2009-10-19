require 'timeout'

module ActionPool

    class Thread
        # :pool:: pool thread is associated with
        # :t_timeout:: max time a thread is allowed to wait for action
        # :a_timeout:: max time thread is allowed to work
        # :respond_thread:: thread to send execptions to
        # :logger:: LogHelper for logging messages
        # Create a new thread
        def initialize(args)
            raise ArgumentError.new('Hash required for initialization') unless args.is_a?(Hash)
            raise ArgumentError.new('ActionPool::Thread requires a pool') unless args[:pool]
            raise ArgumentError.new('ActionPool::Thread requries thread to respond') unless args[:respond_thread]
            @pool = args[:pool]
            @respond_to = args[:respond_thread]
            @thread_timeout = args[:t_timeout] ? args[:t_timeout].to_f : 0
            @action_timeout = args[:a_timeout] ? args[:a_timeout].to_f : 0
            @kill = false
            @logger = args[:logger].is_a?(LogHelper) ? args[:logger] : LogHelper.new(args[:logger])
            @thread = ::Thread.new{ start_thread }
        end

        # :force:: force the thread to stop
        # :wait:: wait for the thread to stop
        # Stop the thread
        def stop(*args)
            @kill = true
            @thread.kill if args.include?(:force) || waiting?
            # killing the thread if it is waiting? is a simple race condition
            # in that, if the thread has just finished a task, but hasn't
            # dropped by the queue line yet, we will see it as not waiting. we
            # can counter that by waiting just a little bit longer than the allowed
            # time to work on an action, and kill the thread if it is still around
            if(args.include?(:wait))
                unless(@thread.join(@action_timeout + 0.01))
                    @thread.kill
                    @thread.join
                end
            end
            nil
        end

        # Is the thread still alive
        def alive?
            @thread.alive?
        end

        # Is the thread currently waiting for input
        def waiting?
            @thread.status == 'sleep'
        end

        # Seconds thread will wait for input
        def thread_timeout
            @thread_timeout
        end

        # Seconds thread will spend working on a given task
        def action_timeout
            @action_timeout
        end

        # t:: seconds to wait for input (floats allow for values 0 < t < 1)
        # Set the maximum amount of time to wait for a task
        def thread_timeout=(t)
            t = t.to_f
            raise ArgumentError.new('Value must be great than zero or nil') unless t > 0
            @thread_timeout = t
            t
        end

        # t:: seconds to work on a task (floats allow for values 0 < t < 1)
        # Set the maximum amount of time to work on a given task
        def action_timeout=(t)
            t = t.to_f
            raise ArgumentError.new('Value must be great than zero or nil') unless t > 0
            @action_timeout = t
            t
        end

        private

        # Start our thread
        def start_thread
            begin
                @logger.info("New pool thread is starting (#{self})")
                until(@kill) do
                    begin
                        action = nil
                        if(@pool.size > @pool.min)
                            Timeout::timeout(@thread_timeout) do
                                action = @pool.action
                            end
                        else
                            action = @pool.action
                        end
                        run(*action) unless action.nil?
                    rescue Timeout::Error => boom
                        @kill = true
                    rescue Exception => boom
                        @logger.error("Pool thread caught an exception: #{boom}\n#{boom.backtrace.join("\n")}")
                        @respond_to.raise boom
                    end
                end
            rescue Exception => boom
                @logger.error("Pool thread caught an exception: #{boom}\n#{boom.backtrace.join("\n")}")
                @respond_to.raise boom
            ensure
                @logger.info("Pool thread is shutting down (#{self})")
                @pool.remove(self)
            end
        end

        # action:: task to be run
        # args:: arguments to be passed to task
        # Run the task
        def run(action, args)
            begin
                if(@action_timeout > 0)
                    Timeout::timeout(@action_timeout) do
                        action.call(*args)
                    end
                else
                    action.call(*args)
                end
            rescue Timeout::Error => boom
                @logger.warn("Pool thread reached max execution time for action: #{boom}")
            end
        end
    end
end