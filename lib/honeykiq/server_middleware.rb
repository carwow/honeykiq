require 'sidekiq/api'

module Honeykiq
  class ServerMiddleware
    def initialize(options = {})
      @honey_client = options[:honey_client]
    end

    def call(_worker, msg, queue_name)
      job = Sidekiq::Job.new(msg, queue_name)

      event = start_span(name: job.display_class)
      call_with_event(event, job, queue_name) { yield }
    rescue StandardError => error
      event&.add_field(:'job.status', 'failed')
      event&.add(error_info(error))
      raise
    ensure
      event&.add(extra_fields)
      event&.send
    end

    def extra_fields
      {}
    end

    private

    def start_span(name:)
      if @honey_client
        @honey_client.event
      else
        Honeycomb.start_span(name: name)
      end
    end

    def call_with_event(event, job, queue_name)
      event.add(default_fields(job, queue_name))
      duration_ms(event) { yield }
      event.add_field(:'job.status', 'finished')
    end

    def default_fields(job, queue_name)
      {
        type: :job,
        **job_fields(job),
        **queue_fields(Sidekiq::Queue.new(queue_name)),
        'meta.thread_id': Thread.current.object_id
      }
    end

    def job_fields(job)
      {
        'job.class': job.display_class,
        'job.attempt_number': (job['retry_count'].to_i.nonzero? || 0) + 1,
        'job.id': job.jid,
        'job.arguments_bytes': job.args.to_json.bytesize,
        'job.latency_sec': job.latency,
        'job.batch_id': job['bid']
      }.compact
    end

    def queue_fields(queue)
      {
        'queue.name': queue.name,
        'queue.size': queue.size
      }
    end

    def duration_ms(event)
      start_time = Time.now
      yield
    ensure
      duration = Time.now - start_time
      event.add_field(:duration_ms, duration * 1000)
    end

    def error_info(error)
      { 'error.class': error.class.name, 'error.message': error.message }
    end
  end
end
