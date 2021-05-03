require "honeycomb-beeline"
require "sidekiq"
require "honeykiq"
require_relative "jobs"

# Configure Honeycomb beeline
Honeycomb.configure do |config|
  config.write_key = ENV.fetch("HONEYCOMB_WRITE_KEY")
  config.dataset = ENV.fetch("HONEYCOMB_DATASET")
end

# To enable sampling uncomment the line below:
# Honeycomb.libhoney.sample_rate = 5

Sidekiq.configure_server do |config|
  # Configure the server client, used when a worker enqueues a job itself.
  config.client_middleware do |chain|
    chain.add Honeykiq::ClientMiddleware
  end

  # Configure ServerMiddleware with a tracing mode
  config.server_middleware do |chain|
    # tracing_mode: options are nil (default), :child, :link
    # - nil (default) will start a span and trace when the job executes.
    # - :child will start a span as a child of the enqueuing trace when the job executes,
    #   requires ClientMiddleware to be configured when enqueuing the job.
    # - :link will start a span and trace with a link event that points to the enqueuing trace,
    #   requires ClientMiddleware to be configured when enqueuing the job.
    #   https://docs.honeycomb.io/getting-data-in/tracing/send-trace-data/#links
    chain.add Honeykiq::ServerMiddleware, tracing_mode: :link
  end
end

# To start the Sidekiq server run: bundle exec sidekiq -r ./server.rb
