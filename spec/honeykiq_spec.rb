RSpec.describe Honeykiq do
  it 'has a version number' do
    expect(described_class::VERSION).not_to be nil
  end

  describe '#periodic_reporter' do
    it 'retuns a PeriodicReporter' do
      expect(described_class.periodic_reporter(honey_client: double))
        .to be_a(described_class::PeriodicReporter)
    end
  end
end
