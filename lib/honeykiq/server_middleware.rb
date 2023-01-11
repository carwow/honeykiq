require "sidekiq/api"

module Honeykiq
  class ServerMiddleware
    def initialize(options = {})
      @libhoney = options[:libhoney] || options[:honey_client]
      @tracing_mode = options[:tracing_mode]
    end

    def call(_worker, msg, queue_name)
      job = Sidekiq::JobRecord.new(msg, queue_name)
      queue = Sidekiq::Queue.new(queue_name)

      span_builder.call(name: job.display_class, serialized_trace: msg["serialized_trace"]) do |event|
        call_with_event(event, job, queue) { yield }
      end
    end

    def extra_fields(_job = nil)
      {}
    end

    private

    attr_reader :libhoney, :tracing_mode

    def libhoney?
      !!libhoney
    end

    def span_builder
      @span_builder ||= libhoney? ? LibhoneySpan.new(libhoney) : BeelineSpan.new(tracing_mode)
    end

    def call_with_event(event, job, queue)
      event.add(default_fields(job, queue))
      yield
      event.add_field(:"job.status", "finished")
    rescue => error
      on_error(event, error)
      raise
    ensure
      event.add(call_extra_fields(job))
    end

    def default_fields(job, queue)
      {
        type: :job,
        **job_fields(job),
        **queue_fields(queue),
        "meta.thread_id": Thread.current.object_id
      }
    end

    def job_fields(job)
      {
        "job.class": job.display_class,
        "job.attempt_number": (job["retry_count"].to_i.nonzero? || 0) + 1,
        "job.id": job.jid,
        "job.arguments_bytes": job.args.to_json.bytesize,
        "job.latency_sec": job.latency,
        "job.batch_id": job["bid"]
      }.compact
    end

    def queue_fields(queue)
      {
        "queue.name": queue.name,
        "queue.size": queue.size
      }
    end

    def on_error(event, error)
      return unless event

      event.add_field(:"job.status", "failed")
      return unless libhoney?

      event.add(
        "error.class": error.class.name,
        "error.message": error.message
      )
    end

    def call_extra_fields(job)
      case method(:extra_fields).arity
      when 0 then extra_fields
      else extra_fields(job)
      end
    end
  end
end
