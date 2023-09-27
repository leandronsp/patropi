class Trampoline
  def initialize(terms, executors)
    @terms = terms
    @executors = executors
    @scope = {}
  end

  def run
    return unless block_given?

    loop do 
      term = @terms.pop
      break if term.nil?

      continuation, result, @scope, location = yield(term, @scope, location)

      begin 
        case [continuation, result]
        in [:raw, result]; perform(result)
        in [:noop, nil]; next
        else raise Error.new(location, "Unknown continuation: #{continuation} with #{result}")
        end
      rescue => e
        raise Error.new(location, "Unexpected error while evaluating continuation: #{e.message}")
      end
    end
  end

  def perform(result)
    executor = @executors.pop
    continuation, result, @scope, location = executor&.call(result)

    return if continuation == :noop

    while executor = @executors.pop
      continuation, result, @scope, location = executor&.call(result)
      break if continuation == :noop
    end
  end
end
