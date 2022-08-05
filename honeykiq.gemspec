require_relative "lib/honeykiq/version"

Gem::Specification.new do |spec|
  spec.name = "honeykiq"
  spec.version = Honeykiq::VERSION
  spec.authors = ["carwow Developers"]
  spec.email = ["developers@carwow.co.uk"]
  spec.summary = "Sidekiq → Honeycomb 🐝"
  spec.description = "Send Sidekiq related events to Honeycomb."
  spec.homepage = "https://github.com/carwow/honeykiq"
  spec.license = "MIT"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(spec|example)/}) }
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "sidekiq", "~> 6.2", ">= 6.2.2"

  spec.add_development_dependency "concurrent-ruby"
  spec.add_development_dependency "honeycomb-beeline", "~> 2.6"
  spec.add_development_dependency "pry", "~> 0.14"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.10"
  spec.add_development_dependency "standard", "~> 0.13"
end
