require 'honeycomb-beeline'
require 'sidekiq/testing'

class TestSidekiqWorker
  include Sidekiq::Worker

  class Error < StandardError; end

  def perform(arg = nil)
    raise Error, 'BOOM' if arg == 'fail'
  end
end

class TestExtraFields < Honeykiq::ServerMiddleware
  def extra_fields
    { extra_data_item: 'foo' }
  end
end

class TestExtraJobFields < Honeykiq::ServerMiddleware
  def extra_fields(job)
    { 'job.arguments': job.args }
  end
end

RSpec.describe Honeykiq::ServerMiddleware do
  let(:libhoney) { Libhoney::TestClient.new }
  let(:test_class) { described_class }

  let(:base_event) do
    {
      type: :job,
      'meta.thread_id': instance_of(Integer),
      'job.class': TestSidekiqWorker.to_s,
      'job.attempt_number': 1,
      'job.id': instance_of(String),
      'job.arguments_bytes': instance_of(Integer),
      'job.latency_sec': be_within(0.5).of(0),
      'job.status': 'finished',
      'queue.name': 'default',
      'queue.size': be_between(0, 100)
    }
  end
  let(:expected_keys) { expected_event.keys }
  let(:expected_error_info) do
    {
      'error.class': TestSidekiqWorker::Error.to_s,
      'error.message': 'BOOM'
    }
  end

  before do
    Sidekiq::Testing.inline!

    allow(Sidekiq::Queue).to receive(:new).with('default') do |name|
      instance_double('Sidekiq::Queue', name: name, size: rand(100))
    end
  end

  shared_examples 'sends event with all fields' do
    it 'sends an event with expected keys' do
      TestSidekiqWorker.perform_async

      expect(libhoney.events.first.data.keys).to match_array(expected_keys)
    end

    it 'sends an event with expected values' do
      TestSidekiqWorker.perform_async

      expect(libhoney.events.first.data).to include(expected_event)
    end

    describe 'adding `extra_fields`' do
      let(:test_class) { TestExtraFields }
      let(:expected_user_event) { expected_event.merge(extra_data_item: 'foo') }

      it 'adds the extra keys' do
        TestSidekiqWorker.perform_async

        expect(libhoney.events.first.data).to include(expected_user_event)
      end
    end

    context 'with job arguments' do
      let(:test_class) { TestExtraJobFields }
      let(:job_arguments) { { 'arg_1' => true, 'arg_2' => true } }
      let(:expected_user_event) do
        expected_event.merge(
          'job.arguments': [job_arguments]
        )
      end

      it 'passes job arguments to `extra_fields`' do
        TestSidekiqWorker.perform_async(job_arguments)

        expect(libhoney.events.first.data).to include(expected_user_event)
      end
    end

    context 'on error' do
      let(:expected_event_for_error) do
        expected_event.merge(
          'job.arguments_bytes': instance_of(Integer),
          'job.status': 'failed'
        ).merge(expected_error_info)
      end

      let(:expected_keys_for_error) { expected_keys + expected_error_info.keys }

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
          expect(libhoney.events.first.data.keys).to match_array(expected_keys_for_error)
        end
      end

      it 'sends an event with expected values' do
        perform do
          expect(libhoney.events.first.data).to include(expected_event_for_error)
        end
      end

      describe 'adding `extra_fields`' do
        let(:test_class) { TestExtraFields }
        let(:expected_user_event) { expected_event_for_error.merge(extra_data_item: 'foo') }

        it 'adds the extra keys' do
          perform do
            expect(libhoney.events.first.data).to include(expected_user_event)
          end
        end
      end
    end

    context 'with batch' do
      before { Sidekiq::Testing.fake! }

      it 'sends an event with extra value' do
        TestSidekiqWorker.perform_async
        TestSidekiqWorker.jobs.first['bid'] = '123'
        TestSidekiqWorker.drain

        expect(libhoney.events.first.data).to include('job.batch_id': '123')
      end
    end

    context 'on retry' do
      before { Sidekiq::Testing.fake! }

      it 'sends an event with extra value' do
        TestSidekiqWorker.perform_async
        TestSidekiqWorker.jobs.first['retry_count'] = 4
        TestSidekiqWorker.drain

        expect(libhoney.events.first.data).to include('job.attempt_number': 5)
      end
    end
  end

  describe 'with Libhoney client' do
    let(:expected_event) do
      base_event.merge(duration_ms: be_within(0.5).of(0))
    end

    before do
      Sidekiq::Testing.server_middleware do |chain|
        chain.clear
        chain.add test_class, libhoney: libhoney
      end
    end

    it_behaves_like 'sends event with all fields'
  end

  describe 'with Honeycomb beeline' do
    subject(:enqueue) do
      parent_span = nil

      Honeycomb.start_span(name: 'test') do |span|
        parent_span = span

        TestSidekiqWorker.perform_async
      end

      parent_span
    end

    let(:expected_error_info) do
      {
        'error' => TestSidekiqWorker::Error.to_s,
        'error_detail' => 'BOOM'
      }
    end

    let(:expected_event) do
      base_event.merge('duration_ms' => be_within(0.5).of(0))
    end

    let(:expected_keys) do
      expected_event.keys + [
        'meta.beeline_version',
        'meta.local_hostname',
        'meta.instrumentations_count',
        'meta.instrumentations',
        'service_name',
        'name',
        'trace.trace_id',
        'trace.span_id',
        'meta.span_type'
      ]
    end

    before do
      Sidekiq::Worker.clear_all

      Honeycomb.configure do |config|
        config.client = libhoney
      end

      Sidekiq::Testing.server_middleware do |chain|
        chain.clear
        chain.add test_class, **server_middleware_params
      end

      Sidekiq.configure_client do |config|
        config.client_middleware do |chain|
          chain.clear
          chain.add Honeykiq::ClientMiddleware
        end
      end

      libhoney.reset
    end

    context 'with no tracing' do
      let(:server_middleware_params) { {} }

      it 'send no additional event' do
        enqueue

        expect(libhoney.events.size).to eq(2)
      end

      it 'does not propagate a trace' do
        parent_span = enqueue

        expect(libhoney.events.first.data).not_to include(
          'trace.parent_id': parent_span.id,
          'trace.trace_id': parent_span.trace.id
        )
      end
    end

    context 'when tracing via link events' do
      let(:server_middleware_params) { { tracing_mode: :link } }

      it 'sends an additional event' do
        enqueue

        expect(libhoney.events.size).to eq(3)
      end

      it 'propagates the trace' do
        parent_span = enqueue

        expect(libhoney.events.first.data).to include(
          'trace.link.trace_id': parent_span.trace.id,
          'trace.link.span_id': parent_span.id,
          'meta.annotation_type': 'link',
          'trace.parent_id': kind_of(String),
          'trace.trace_id': kind_of(String)
        )
      end
    end

    context 'when tracing via child event' do
      let(:parent_span) { enqueue }
      let(:server_middleware_params) { { tracing_mode: :child } }
      let(:expected_event) do
        super().merge(
          'trace.parent_id' => parent_span.id,
          'trace.trace_id' => parent_span.trace.id
        )
      end

      before { parent_span }

      it 'send no additional event' do
        expect(libhoney.events.size).to eq(2)
      end

      it 'propagates the trace' do
        expect(libhoney.events.first.data).to include(expected_event)
      end
    end
  end
end
