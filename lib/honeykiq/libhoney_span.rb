module Honeykiq
  class LibhoneySpan
    def initialize(libhoney)
      @libhoney = libhoney
    end

    def call(*)
      libhoney.event.tap do |event|
        duration_ms(event) { yield event }
      ensure
        event.send
      end
    end

    private

    attr_reader :libhoney

    def duration_ms(event)
      start_time = now
      yield
    ensure
      duration = now - start_time
      event.add_field(:duration_ms, duration * 1000)
    end

    if defined?(Process::CLOCK_MONOTONIC)
      def now
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
    else
      def now
        Time.now
      end
    end
  end
end
