class Fib
  include Sidekiq::Worker

  def perform(target, current = 1, current_value = 1, previous_value = 0)
    Honeycomb.current_span.add(
      target: target,
      current: current,
      current_value: current_value,
      previous_value: previous_value
    )

    return Sidekiq.logger.info previous_value if current > target
    return Sidekiq.logger.info current_value if target == current

    Fib.perform_async(target, current + 1, current_value + previous_value, current_value)
  end
end
