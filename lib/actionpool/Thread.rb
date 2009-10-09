require 'timeout'

module ActionPool
    class Thread
        # pool:: pool thread is associated with
        # t_timeout:: max time a thread is allowed to wait for action
        # a_timeout:: max time thread is allowed to work
        # respond:: thread to send execptions to
        # logger:: LogHelper for logging messages
        # Create a new thread
        def initialize(pool, t_timeout, a_timeout, respond_thread, logger=nil)
            @pool = pool
            @pool_timeout = t_timeout.nil? ? 0 : t_timeout
            @action_timeout = a_timeout.nil? ? 0 : a_timeout
            @kill = false
            @logger = logger
            @respond_to = respond_thread
            @thread = ::Thread.new{ start_thread }
        end

        # stop the thread
        def stop(force=false)
            @kill = true
            @thread.kill if force
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
                        run(action) unless action.nil?
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

        def run(action)
            begin
                if(@action_timeout > 0)
                    Timeout::timeout(@action_timeout) do
                        action.call
                    end
                else
                    action.call
                end
            rescue Timeout::Error => boom
                @logger.warn("Pool thread reached max execution time for action: #{boom}")
            end
        end
    end
end