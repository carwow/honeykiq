# Honeykiq

Sidekiq → Honeycomb 🐝

Send Sidekiq related events to Honeycomb.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'honeykiq'
```

## Usage

At the moment the library only provides a periodic reporter which should be
scheduled to report every few seconds depending on your use case.

### Honeykiq::PeriodicReporter

The periodic reporter will send one event with information about the sidekiq
instance, plus one event per sidekiq process, plus one event per sidekiq queue.
Have a look at [periodic_reporter.rb] to see what kind of information we send
for each type.

[periodic_reporter.rb]: https://github.com/carwow/honeykiq/blob/master/lib/honeykiq/periodic_reporter.rb

A simple setup using [clockwork] would look like this:

[clockwork]: https://github.com/adamwiggins/clockwork

```ruby
require 'clockwork'
require 'libhoney'
require 'honeykiq'

module Clockwork
  every(30, 'Honeykiq', thread: true) { SidekiqHealth.report }
end

module SidekiqHealth
  def self.report
    reporter.report
  end

  def self.reporter
    @reporter ||= Honeykiq::PeriodicReporter.new(honey_client: honey_client)
  end

  def self.honey_client
    Libhoney::Client.new(
      writekey: ENV.fetch('HONEYCOMB_WRITE_KEY'),
      dataset: ENV.fetch('HONEYCOMB_DATASET')
    )
  end
end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/carwow/honeykiq.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
