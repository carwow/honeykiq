require 'libhoney'
require 'sidekiq/testing'

class TestSidekiqWorker
  include Sidekiq::Worker

  class Error < StandardError; end

  def perform(arg = nil)
    raise Error, 'BOOM' if arg == 'fail'
  end
end

RSpec.describe Honeykiq::ServerMiddleware do
  let(:reporter) { described_class.new(honey_client: honey_client) }
  let(:honey_client) { Libhoney::TestClient.new }

  let(:expected_event) do
    {
      type: :job,
      'meta.thread_id': instance_of(Integer),
      'job.class': TestSidekiqWorker.to_s,
      'job.attempt_number': 1,
      'job.id': instance_of(String),
      'job.arguments_bytes': 2,
      'job.latency_sec': be_within(0.01).of(0),
      'job.status': 'finished',
      'queue.name': 'default',
      'queue.size': be_between(0, 100),
      'duration_ms': be_within(0.05).of(0)
    }
  end

  before do
    Sidekiq::Testing.inline!

    Sidekiq::Testing.server_middleware do |chain|
      chain.add described_class, honey_client: honey_client
    end

    allow(Sidekiq::Queue).to receive(:new).with('default') do |name|
      instance_double('Sidekiq::Queue', name: name, size: rand(100))
    end
  end

  it 'sends an event with expected keys' do
    TestSidekiqWorker.perform_async

    expect(honey_client.events.first.data.keys.sort).to eq(expected_event.keys.sort)
  end

  it 'sends an event with expected values' do
    TestSidekiqWorker.perform_async

    expect(honey_client.events.first.data).to include(expected_event)
  end

  context 'on error' do
    let(:expected_event_for_error) do
      expected_event.merge(
        'job.arguments_bytes': 8,
        'job.status': 'failed',
        'error.class': TestSidekiqWorker::Error.to_s,
        'error.message': 'BOOM'
      )
    end

    def perform(&block)
      aggregate_failures do
        expect { TestSidekiqWorker.perform_async('fail') }.to raise_error(TestSidekiqWorker::Error)

        block&.call
      end
    end

    it 'raises the error' do
      perform
    end

    it 'sends an event with expected keys' do
      perform do
        expect(honey_client.events.first.data.keys.sort).to eq(expected_event_for_error.keys.sort)
      end
    end

    it 'sends an event with expected values' do
      perform do
        expect(honey_client.events.first.data).to include(expected_event_for_error)
      end
    end
  end

  context 'with batch' do
    before { Sidekiq::Testing.fake! }

    it 'sends an event with extra value' do
      TestSidekiqWorker.perform_async
      TestSidekiqWorker.jobs.first['bid'] = '123'
      TestSidekiqWorker.drain

      expect(honey_client.events.first.data).to include('job.batch_id': '123')
    end
  end

  context 'on retry' do
    before { Sidekiq::Testing.fake! }

    it 'sends an event with extra value' do
      TestSidekiqWorker.perform_async
      TestSidekiqWorker.jobs.first['retry_count'] = 4
      TestSidekiqWorker.drain

      expect(honey_client.events.first.data).to include('job.attempt_number': 5)
    end
  end
end
