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

  spec.required_ruby_version = ">= 2.7"

  spec.add_dependency "sidekiq", ">= 6.2.2", "<8"

  spec.add_development_dependency "honeycomb-beeline", "~> 2"
  spec.add_development_dependency "pry", "~> 0.14"
  spec.add_development_dependency "rake", "~> 13"
  spec.add_development_dependency "rspec", "~> 3"
  spec.add_development_dependency "standard", "~> 1"
end
