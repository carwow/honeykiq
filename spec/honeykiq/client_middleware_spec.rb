require 'honeycomb-beeline'
require 'sidekiq/testing'

class TestSidekiqWorker
  include Sidekiq::Worker

  def perform; end
end

RSpec.describe Honeykiq::ClientMiddleware do
  let(:libhoney) { Libhoney::TestClient.new }

  before do
    Sidekiq::Worker.clear_all
    Sidekiq::Testing.fake!

    Honeycomb.configure do |config|
      config.client = libhoney
    end

    Sidekiq.configure_client do |config|
      config.client_middleware do |chain|
        chain.clear
        chain.add described_class
      end
    end
  end

  context 'when within a span' do
    it 'adds serialized_trace to the job' do
      expected_span = nil

      Honeycomb.start_span(name: 'test') do |span|
        expected_span = span

        TestSidekiqWorker.perform_async
      end

      job = TestSidekiqWorker.jobs.first

      expect(job['serialized_trace']).to eq(expected_span.to_trace_header)
    end
  end

  context 'when not within a span' do
    it 'does not set serialized_trace' do
      TestSidekiqWorker.perform_async

      job = TestSidekiqWorker.jobs.first

      expect(job['serialized_trace']).to be_nil
    end
  end
end
