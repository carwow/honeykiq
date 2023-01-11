require "honeycomb-beeline"
require "clockwork"
require "honeykiq"

# Configure Honeycomb beeline
Honeycomb.configure do |config|
  config.write_key = ENV.fetch("HONEYCOMB_WRITE_KEY")
  config.dataset = ENV.fetch("HONEYCOMB_DATASET")
end

module Clockwork
  every(5, "Honeykiq::PeriodicReporter") do
    Honeykiq::PeriodicReporter.new.report
  end
end

# To start the clockwork process run: bundle exec clockwork reporter.rb
