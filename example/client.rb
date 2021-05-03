require "honeycomb-beeline"
require "sidekiq"
require "honeykiq"
require_relative "jobs"

# Configure Honeycomb beeline
Honeycomb.configure do |config|
  config.write_key = ENV.fetch("HONEYCOMB_WRITE_KEY")
  config.dataset = ENV.fetch("HONEYCOMB_DATASET")
end

# Add the middleware to Sidekiq chain
Sidekiq.configure_client do |config|
  config.client_middleware do |chain|
    chain.add Honeykiq::ClientMiddleware
  end
end

Fib.perform_async(10)
