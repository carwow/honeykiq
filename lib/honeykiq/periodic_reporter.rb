require 'sidekiq/api'

module Honeykiq
  class PeriodicReporter
    def initialize(honey_client:)
      @honey_client = honey_client
    end

    def report(&extra)
      send_instance_event(&extra)
      Sidekiq::ProcessSet.new.each { |process| send_process_event(process, &extra) }
      Sidekiq::Queue.all.each { |queue| send_queue_event(queue, &extra) }
    end

    private

    attr_reader :honey_client

    def send_instance_event(&extra)
      honey_client.event.add(
        type: :instance,
        **instance_stats,
        **redis_stats,
        **(extra&.call(:instance) || {})
      ).send
    end

    def instance_stats
      stats = Sidekiq::Stats.new

      {
        'instance.processes': stats.processes_size,
        'instance.busy': stats.workers_size,
        'instance.enqueued': stats.enqueued,
        'instance.scheduled': stats.scheduled_size,
        'instance.retries': stats.retry_size,
        'instance.dead': stats.dead_size
      }
    end

    def redis_stats
      redis_info = fetch_redis_info

      {
        'redis.connections': redis_info['connected_clients'].to_i,
        'redis.memory_used': redis_info['used_memory'].to_i
      }
    end

    def fetch_redis_info
      Sidekiq.redis do |redis|
        redis.pipelined do
          redis.info :clients
          redis.info :memory
        end.reduce(&:merge)
      end
    end

    def send_process_event(process, &extra)
      honey_client.event.add(
        type: :process,
        'meta.dyno': process['hostname'],
        'meta.process_id': process['pid'],
        'process.concurrency': process['concurrency'],
        'process.busy': process['busy'],
        **(extra&.call(:process, process) || {})
      ).send
    end

    def send_queue_event(queue, &extra)
      honey_client.event.add(
        type: :queue,
        'queue.name': queue.name,
        'queue.latency_sec': queue.latency.to_f,
        'queue.size': queue.size,
        **(extra&.call(:queue, queue) || {})
      ).send
    end
  end
end
