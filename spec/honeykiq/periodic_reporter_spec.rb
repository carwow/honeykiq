require 'honeykiq'
require 'libhoney'

RSpec.describe Honeykiq::PeriodicReporter do
  let(:reporter) { described_class.new(honey_client: honey_client) }
  let(:honey_client) { Libhoney::TestClient.new }

  let(:stats) do
    instance_double(Sidekiq::Stats,
      processes_size: 1,
      workers_size: 5,
      enqueued: 1000,
      scheduled_size: 2000,
      retry_size: 33,
      dead_size: 22
    )
  end

  let(:redis_info) { { 'connected_clients' => '5', 'used_memory' => '123' } }
  let(:processes) { [process] }
  let(:process) { { 'hostname' => 'sla_worker.1', 'pid' => 4, 'concurrency' => 10, 'busy' => 5 } }
  let(:queues) { [queue] }
  let(:queue) { instance_double('Sidekiq::Queue', name: SecureRandom.uuid, latency: 1.0, size: 10) }

  let(:expected_instance_event) do
    {
      type: :instance,
      'instance.processes': stats.processes_size,
      'instance.busy': stats.workers_size,
      'instance.enqueued': stats.enqueued,
      'instance.scheduled': stats.scheduled_size,
      'instance.retries': stats.retry_size,
      'instance.dead': stats.dead_size,
      'redis.connections': redis_info['connected_clients'].to_i,
      'redis.memory_used': redis_info['used_memory'].to_i
    }
  end

  let(:expected_process_event) do
    {
      type: :process,
      'meta.dyno': process['hostname'],
      'meta.process_id': process['pid'],
      'process.concurrency': process['concurrency'],
      'process.busy': process['busy']
    }
  end

  let(:expected_queue_event) do
    {
      type: :queue,
      'queue.name': queue.name,
      'queue.latency_sec': queue.latency,
      'queue.size': queue.size
    }
  end

  before do
    allow(reporter).to receive(:fetch_redis_info).and_return(redis_info)
    allow(Sidekiq::Stats).to receive(:new).and_return(stats)
    allow(Sidekiq::ProcessSet).to receive(:new).and_return(processes)
    allow(Sidekiq::Queue).to receive(:all).and_return(queues)
  end

  it '#report for instance' do
    reporter.report

    expect(honey_client.events.first.data).to eq(expected_instance_event)
  end

  it '#report for process' do
    reporter.report

    expect(honey_client.events.drop(1).first.data).to eq(expected_process_event)
  end

  it '#report for queue' do
    reporter.report

    expect(honey_client.events.drop(2).first.data).to eq(expected_queue_event)
  end

  context 'with extra fields' do
    it '#report for instance' do
      reporter.report { |type| { extra: 'cool' } if type == :instance }

      expect(honey_client.events.first.data)
        .to eq(expected_instance_event.merge(extra: 'cool'))
    end

    it '#report for process' do
      reporter.report { |type, process| { extra: process['hostname'] } if type == :process }

      expect(honey_client.events.drop(1).first.data)
        .to eq(expected_process_event.merge(extra: process['hostname']))
    end

    it '#report for queue' do
      reporter.report { |type, queue| { extra: queue.name } if type == :queue }

      expect(honey_client.events.drop(2).first.data)
        .to eq(expected_queue_event.merge(extra: queue.name))
    end
  end
end
