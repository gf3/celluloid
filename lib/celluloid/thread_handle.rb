module Celluloid
  # An abstraction around threads from the InternalPool which ensures we don't
  # accidentally do things to threads which have been returned to the pool,
  # such as, say, killing them
  class ThreadHandle
    def initialize
      @mutex = Mutex.new
      @join  = ConditionVariable.new

      @thread = Celluloid.internal_pool.get do
        begin
          yield
        ensure
          @mutex.synchronize do
            @thread = nil
            @join.broadcast
          end
        end
      end
    end

    # Is the thread running?
    def alive?
      @mutex.synchronize { @thread.alive? if @thread }
    end

    # Forcibly kill the thread
    def kill
      !!@mutex.synchronize { @thread.kill if @thread }
      self
    end

    # Join to a running thread, blocking until it terminates
    def join
      @mutex.synchronize { @join.wait(@mutex) if @thread }
      self
    end

    # Obtain the backtrace for this thread
    def backtrace
      @thread.backtrace
    rescue NoMethodError
      # undefined method `backtrace' for nil:NilClass
      # Swallow this in case this ThreadHandle was terminated and @thread was
      # set to nil
    end
  end
end
