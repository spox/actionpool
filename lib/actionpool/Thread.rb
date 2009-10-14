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
            @thread_timeout = args[:t_timeout] ? args[:t_timeout] : 0
            @action_timeout = args[:a_timeout] ? args[:a_timeout] : 0
            @kill = false
            @logger = args[:logger].is_a?(LogHelper) ? args[:logger] : LogHelper.new(args[:logger])
            @thread = ::Thread.new{ start_thread }
        end

        # force:: force the thread to stop
        # Stop the thread
        def stop(force=false)
            @kill = true
            @thread.kill if force
            nil
        end

        private

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