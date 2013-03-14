require 'celluloid'
require 'timeout'

module ActionPool
  class Worker
    include Celluloid

    attr_reader :pool

    def initialize(pool)
      @pool = pool
    end

    def block_call(pr, *args)
      if(pool.action_timeout.to_i > 0)
        begin
          Timeout::timeout(pool.action_timeout.to_i) do
            pr.call(*args)
          end
        rescue Timeout::Error
          # Die quietly
        end
      else
        pr.call(*args)
      end
    end

    def object_call(base_obj, method, object)
      if(pool.action_timeout.to_i > 0)
        begin
          Timeout::timeout(pool.action_timeout.to_i) do
            base_obj.send(method, object)
          end
        rescue Timeout::Error
          # Die quietly
        end
      else
        base_obj.send(method, object)
      end
    end
  end
end
