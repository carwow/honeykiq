lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'honeykiq/version'

Gem::Specification.new do |spec|
  spec.name          = 'honeykiq'
  spec.version       = Honeykiq::VERSION
  spec.authors       = ['carwow Developers']
  spec.email         = ['developers@carwow.co.uk']
  spec.summary       = 'Sidekiq → Honeycomb 🐝'
  spec.description   = 'Send Sidekiq related events to Honeycomb.'
  spec.homepage      = 'https://github.com/carwow/honeykiq'
  spec.license       = 'MIT'

  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.require_paths = ['lib']

  spec.add_dependency 'sidekiq'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'carwow_rubocop'
  spec.add_development_dependency 'honeycomb-beeline'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
end
