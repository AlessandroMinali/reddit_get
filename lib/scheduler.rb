# frozen_string_literal: true

# This is an example and simplified scheduler for test purposes.
# It is not efficient for a large number of file descriptors as it uses IO.select().
# Production Fiber schedulers should use epoll/kqueue/etc.

require 'fiber'
require 'socket'

begin
  require 'io/nonblock'
rescue LoadError
  # Ignore.
end

module RedditGet
  class Scheduler
    def initialize
      @readable = {}
      @writable = {}
      @waiting = {}

      @closed = false

      @lock = Mutex.new
      @blocking = 0
      @ready = []

      @urgent = IO.pipe
    end

    attr :readable, :writable, :waiting

    def next_timeout
      _fiber, timeout = @waiting.min_by { |_key, value| value }

      if timeout
        offset = timeout - current_time

        if offset.negative?
          0
        else
          offset
        end
      end
    end

    def run
      while @readable.any? || @writable.any? || @waiting.any? || @blocking.positive?
        # Can only handle file descriptors up to 1024...
        readable, writable = IO.select(@readable.keys + [@urgent.first], @writable.keys, [],
                                       next_timeout)

        # puts "readable: #{readable}" if readable&.any?
        # puts "writable: #{writable}" if writable&.any?

        readable&.each do |io|
          if fiber = @readable.delete(io)
            fiber.resume
          elsif io == @urgent.first
            @urgent.first.read_nonblock(1024)
          end
        end

        writable&.each do |io|
          if fiber = @writable.delete(io)
            fiber.resume
          end
        end

        if @waiting.any?
          time = current_time
          waiting = @waiting
          @waiting = {}

          waiting.each do |fiber, timeout|
            if timeout <= time
              fiber.resume
            else
              @waiting[fiber] = timeout
            end
          end
        end

        next unless @ready.any?

        ready = nil

        @lock.synchronize do
          ready = @ready
          @ready = []
        end

        ready.each(&:resume)
      end
    end

    def close
      raise 'Scheduler already closed!' if @closed

      run
    ensure
      @urgent.each(&:close)
      @urgent = nil

      @closed = true

      # We freeze to detect any unintended modifications after the scheduler is closed:
      freeze
    end

    def closed?
      @closed
    end

    def current_time
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def process_wait(pid, flags)
      # This is a very simple way to implement a non-blocking wait:
      Thread.new do
        Process::Status.wait(pid, flags)
      end.value
    end

    def io_wait(io, events, _duration)
      @readable[io] = Fiber.current unless (events & IO::READABLE).zero?

      @writable[io] = Fiber.current unless (events & IO::WRITABLE).zero?

      Fiber.yield
      events
    end

    # Used for Kernel#sleep and Mutex#sleep
    def kernel_sleep(duration = nil)
      block(:sleep, duration)

      true
    end

    # Used when blocking on synchronization (Mutex#lock, Queue#pop, SizedQueue#push, ...)
    def block(_blocker, timeout = nil)
      # $stderr.puts [__method__, blocker, timeout].inspect

      if timeout
        @waiting[Fiber.current] = current_time + timeout
        begin
          Fiber.yield
        ensure
          # Remove from @waiting in the case #unblock was called before the timeout expired:
          @waiting.delete(Fiber.current)
        end
      else
        @blocking += 1
        begin
          Fiber.yield
        ensure
          @blocking -= 1
        end
      end
    end

    # Used when synchronization wakes up a previously-blocked fiber (Mutex#unlock, Queue#push, ...).
    # This might be called from another thread.
    def unblock(_blocker, fiber)
      # $stderr.puts [__method__, blocker, fiber].inspect

      @lock.synchronize do
        @ready << fiber
      end

      io = @urgent.last
      io.write_nonblock('.')
    end

    def fiber(&block)
      fiber = Fiber.new(blocking: false, &block)

      fiber.resume

      fiber
    end
  end
end
