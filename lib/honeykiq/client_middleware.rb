module Honeykiq
  class ClientMiddleware
    def call(_, job, _, _)
      job['serialized_trace'] = Honeycomb.current_span&.to_trace_header

      yield
    end
  end
end
