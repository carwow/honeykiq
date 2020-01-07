require 'sidekiq/api'

module Honeykiq
  class ServerMiddleware
    def initialize(options = {})
      @honey_client = options.fetch(:honey_client)
    end

    def call(_worker, msg, queue_name)
      event = @honey_client.event
      run_event(event, msg, queue_name) { yield }
      event.add_field(:'job.status', 'finished')
    rescue StandardError => error
      event&.add_field(:'job.status', 'failed')
      event&.add(error_info(error))
      raise
    ensure
      event&.send
    end

    def before_fields
      {}
    end

    def after_fields
      {}
    end

    private

    def default_fields(msg, queue_name)
      {
        type: :job,
        **job_fields(Sidekiq::Job.new(msg, queue_name)),
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

    def run_event(event, msg, queue_name)
      event.add(**default_fields(msg, queue_name))
      event.add(**before_fields)
      start_time = Time.now
      yield
      event.add(**after_fields)
    ensure
      duration = Time.now - start_time
      event.add_field(:duration_ms, duration * 1000)
    end

    def error_info(error)
      { 'error.class': error.class.name, 'error.message': error.message }
    end
  end
end
