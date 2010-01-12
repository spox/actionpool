require 'timeout'

module ActionPool
    # Exception class used for waking up a thread
    class Wakeup < StandardError
    end
    # Raised within a thread when the timeout is changed
    class Retimeout < StandardError
    end
    class Thread
        # :pool:: pool thread is associated with
        # :t_timeout:: max time a thread is allowed to wait for action
        # :a_timeout:: max time thread is allowed to work
        # :respond_thread:: thread to send execptions to
        # :logger:: LogHelper for logging messages
        # :autostart:: Automatically start the thread
        # Create a new thread
        def initialize(args)
            raise ArgumentError.new('Hash required for initialization') unless args.is_a?(Hash)
            raise ArgumentError.new('ActionPool::Thread requires a pool') unless args[:pool]
            raise ArgumentError.new('ActionPool::Thread requries thread to respond') unless args[:respond_thread]
            @pool = args[:pool]
            @respond_to = args[:respond_thread]
            @thread_timeout = args[:t_timeout] ? args[:t_timeout].to_f : 0
            @action_timeout = args[:a_timeout] ? args[:a_timeout].to_f : 0
            args[:autostart] = true unless args.has_key?(:autostart)
            @kill = false
            @logger = args[:logger].is_a?(Logger) ? args[:logger] : Logger.new(nil)
            @lock = Splib::Monitor.new
            @action = nil
            @thread = args[:autostart] ? ::Thread.new{ start_thread } : nil
        end

        def start
            @thread = ::Thread.new{ start_thread } if @thread.nil?
        end
        
        # :force:: force the thread to stop
        # :wait:: wait for the thread to stop
        # Stop the thread
        def stop(*args)
            @kill = true
            if(args.include?(:force) || waiting?)
                begin
                    @thread.raise Wakeup.new
                rescue Wakeup
                    #ignore since we are the caller
                end
                sleep(0.01)
                @thread.kill if @thread.alive?
            end
            nil
        end

        # Currently waiting
        def waiting?
            @action.nil?
#             @status == :wait
        end

        # Currently running
        def running?
            !@action.nil?
#             @status == :run
        end

        # Is the thread still alive
        def alive?
            @thread.alive?
        end

        # Current thread status
        def status
            @action
        end

        # Join internal thread
        def join
            @thread.join(@action_timeout)
            if(@thread.alive?)
                @thread.kill
                @thread.join
            end
        end

        # Kill internal thread
        def kill
            @thread.kill
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
            @thread.raise Retimeout.new if waiting?
            t
        end

        # t:: seconds to work on a task (floats allow for values 0 < t < 1)
        # Set the maximum amount of time to work on a given task
        # Note: Modification of this will not affect actions already in process
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
                        @action = nil
                        if(@pool.size > @pool.min && !@thread_timeout.zero?)
                            Timeout::timeout(@thread_timeout) do
                                @action = @pool.action
                            end
                        else
                            @action = @pool.action
                        end
                        run(@action[0], @action[1]) unless @action.nil?
                    rescue Timeout::Error
                        @kill = true
                    rescue Wakeup
                        @logger.info("Thread #{::Thread.current} was woken up.")
                    rescue Retimeout
                        @logger.warn('Thread was woken up to reset thread timeout')
                    rescue Exception => boom
                        @logger.error("Pool thread caught an exception: #{boom}\n#{boom.backtrace.join("\n")}")
                        @respond_to.raise boom
                    end
                end
            rescue Retimeout
                @logger.warn('Thread was woken up to reset thread timeout')
                retry
            rescue Wakeup
                @logger.info("Thread #{::Thread.current} was woken up.")
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
            args = args.respond_to?(:fixed_flatten) ? args.fixed_flatten(1) : args.flatten(1)
            begin
                unless(@action_timeout.zero?)
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