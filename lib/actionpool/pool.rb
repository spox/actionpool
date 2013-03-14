require 'logger'
require 'thread'
require 'splib'
require 'celluloid'
require 'actionpool/queue_processor'
require 'actionpool/worker'

module ActionPool
  class Pool

    attr_accessor :action_timeout

    # :a_to:: maximum time action may be worked on before aborting
    # :logger:: logger to print logging messages to
    # :pqueue:: use a priority queue (defaults to false)
    # :pool_args:: hash passed to pool
    # Creates a new pool
    def initialize(args={})
      @action_timeout = args[:a_to].to_f
      Splib.load :priority_queue if args[:pqueue]
      pool = Worker.pool({size: 4, args: [self]}.merge(args[:pool_args] || {}))
      Celluloid::Actor[:action_pool_workers] = pool
      q_proc = QueueProcessor.new(pool)
      Celluloid::Actor[:action_pool_processor] = q_proc
    end

    def queue
      processor
    end

    def shutdown
      processor.halt
      processor.terminate
      pool.terminate
    end

    def pool
      Celluloid::Actor[:action_pool_workers]
    end
    
    def processor
      Celluloid::Actor[:action_pool_processor]
    end

    # action:: proc to be executed or array of [proc, [*args]]
    # Add a new proc/lambda to be executed (alias for queue)
    def <<(action)
      case action
        when Proc
          queue(action)
        when Array
          raise ArgumentError.new('Actions to be processed by the pool must be a proc/lambda or [proc/lambda, [*args]]') unless action.size == 2 and action[0].is_a?(Proc) and action[1].is_a?(Array)
          queue(action.first, *action.last)
        else
          raise ArgumentError.new('Actions to be processed by the pool must be a proc/lambda or [proc/lambda, [*args]]')
      end
      nil
    end

    # action:: proc to be executed
    # Add a new proc/lambda to be executed
    def queue(*args, &block)
      raise ArgumentError.new('Expecting block') unless block || args.first.is_a?(Proc)
      if(block)
        action = block
      else
        action = args.shift
      end
      processor << [action, args]
    end

    # jobs:: Array of proc/lambdas
    # Will queue a list of jobs into the pool
    def add_jobs(jobs)
      raise ArgumentError.new("Expecting an array but received: #{jobs.class}") unless jobs.is_a?(Array)
      processor.pause
      begin
        jobs.each do |job|
          case job
          when Proc
            processor << [job, []]
          when Array
            raise ArgumentError.new('Jobs to be processed by the pool must be a proc/lambda or [proc/lambda, [*args]]') unless job.size == 2 and job[0].is_a?(Proc) and job[1].is_a?(Array)
            processor << [job.first, job.last]
          else
            raise ArgumentError.new('Jobs to be processed by the pool must be a proc/lambda or [proc/lambda, [*args]]')
          end
        end
      ensure
        processor.unpause
      end
      true
    end

    # block:: block to process
    # Adds a block to be processed
    def process(*args, &block)
      queue(block, *args)
      nil
    end

    # Number of actions in the queue
    def action_size
      processor.size
    end
  end
end
