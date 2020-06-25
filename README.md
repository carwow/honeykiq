# Honeykiq

Sidekiq → Honeycomb 🐝

Send [Sidekiq](https://sidekiq.org)-related events to
[Honeycomb](https://www.honeycomb.io).

## Installation

Add this line to your application's `Gemfile`:

```ruby
gem 'honeykiq'
```

## Usage

The library provides two use cases:

- [`Honeykiq::ServerMiddleware`]
- [`Honeykiq::PeriodicReporter`]

[`Honeykiq::ServerMiddleware`]: #HoneykiqServerMiddleware
[`Honeykiq::PeriodicReporter`]: #HoneykiqPeriodicReporter

### Honeykiq::ServerMiddleware

Add Honeykiq to your Sidekiq server middleware chain. It will send an event to
Honeycomb once a job finishes or fails. Have a look at [server_middleware.rb]
to see what kind of information it sends.

[server_middleware.rb]: https://github.com/carwow/honeykiq/blob/master/lib/honeykiq/server_middleware.rb

```ruby
# Configure Honeycomb beeline
Honeycomb.configure do |config|
  config.writekey = ENV.fetch('HONEYCOMB_WRITE_KEY')
  config.dataset = ENV.fetch('HONEYCOMB_DATASET')
end

# Add the middleware to Sidekiq chain
Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add Honeykiq::ServerMiddleware
  end
end

# Or pass the libhoney client to the middleware
Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add Honeykiq::ServerMiddleware,
      libhoney: Libhoney::Client.new(
        writekey: ENV.fetch('HONEYCOMB_WRITE_KEY'),
        dataset: ENV.fetch('HONEYCOMB_DATASET')
      )
  end
end
```

You can add your own data or functions to the Honeycomb event by subclassing
`Honeykiq::ServerMiddleware`, and overriding the `extra_fields` method with
your own hash. The contents will be serialized into individual items in the
event:

```ruby
class MyServerMiddleware < Honeykiq::ServerMiddleware
  def extra_fields
    {
      my_data: 'evaluated and added to the event after the job has finished/errored',
      my_function: -> { Time.now }
    }
  end
end

Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add MyServerMiddleware
  end
end
```

**Note:** If you have long running jobs, an event is only sent to Honeycomb
when the job finishes. Therefore, it may appear as though no jobs are currently
running.  Additionally, if the process receives a `SIGKILL` then no event is
sent about that job, and the job may keep retrying without appearing in
Honeycomb. The `PeriodicReporter` provides visibility for these cases.

### Honeykiq::PeriodicReporter

The periodic reporter should be scheduled to report every few seconds,
depending on your use case. Every time the `#report` method is called it will
send a total of `1 + P + Q` events to Honeycomb where `P` and `Q` are the
number of processes and queues respectively.

It sends three types of events: `instance`, `process`, and `queue`. Have a look
at [periodic_reporter.rb] to see what kind of information we send for each
type.

[periodic_reporter.rb]: https://github.com/carwow/honeykiq/blob/master/lib/honeykiq/periodic_reporter.rb

A setup using [clockwork] to report every 30 seconds would look like this:

```ruby
require 'honeycomb-beeline'
require 'clockwork'
require 'honeykiq'

Honeycomb.configure do |config|
  config.writekey = ENV.fetch('HONEYCOMB_WRITE_KEY')
  config.dataset = ENV.fetch('HONEYCOMB_DATASET')
end

module Clockwork
  every(30, 'Honeykiq::PeriodicReporter') do
    Honeykiq::PeriodicReporter.new.report
  end
end
```

[clockwork]: https://github.com/Rykian/clockwork

## Contributing

[Pull requests](https://github.com/carwow/honeykiq/pulls) are very welcome!

Please report bugs in a [new issue](https://github.com/carwow/honeykiq/issues/new).

## License

The gem is available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).
