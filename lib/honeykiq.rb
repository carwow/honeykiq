module Honeykiq
  autoload :Version, 'honeykiq/version'
  autoload :PeriodicReporter, 'honeykiq/periodic_reporter'

  def self.periodic_reporter(honey_client:)
    @reporter = Honeykiq::PeriodicReporter.new(honey_client: honey_client)
  end
end
