require 'honeykiq'
require 'pry'

RSpec.configure do |config|
  Kernel.srand config.seed
  config.default_formatter = 'doc' if config.files_to_run.one?
  config.disable_monkey_patching!
  config.example_status_persistence_file_path = '.rspec_status'
  config.filter_run_when_matching :focus
  config.order = :random
  config.profile_examples = 1
  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end
