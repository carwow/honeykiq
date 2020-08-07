module Honeykiq
  class BeelineSpan
    def initialize(tracing_mode)
      @tracing_mode = tracing_mode
    end

    def call(name:, serialized_trace:, &block)
      case tracing_mode
      when :link  then link_span(name, serialized_trace, &block)
      when :child then child_span(name, serialized_trace, &block)
      else
        Honeycomb.start_span(name: name, &block)
      end
    end

    private

    attr_reader :tracing_mode

    def link_span(name, serialized_trace)
      Honeycomb.start_span(name: name) do |event|
        link_to_enqueuing_trace(event, serialized_trace)

        yield event
      end
    end

    def child_span(name, serialized_trace)
      Honeycomb.start_span(name: name, serialized_trace: serialized_trace) do |event|
        yield event
      end
    end

    def link_to_enqueuing_trace(current, serialized_trace)
      return unless serialized_trace

      trace_id, parent_span_id, = TraceParser.parse(serialized_trace)

      Honeycomb.libhoney.event.add(
        'trace.link.trace_id': trace_id,
        'trace.link.span_id': parent_span_id,
        'meta.span_type': 'link',
        'trace.parent_id': current.id,
        'trace.trace_id': current.trace.id
      ).send
    end

    if defined?(Honeycomb)
      class TraceParser
        extend Honeycomb::PropagationParser
      end
    end
  end
end
