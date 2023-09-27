class Evaluators::TupleAccess 
  def self.evaluate(*args) = new(*args).evaluate

  def initialize(data, scope, terms, executors, index)
    @data = data
    @scope = scope
    @terms = terms
    @executors = executors
    @index = index
  end

  def evaluate
    value, location = @data.values_at(:value, :location)

    @terms.push(value)

    @executors.push(-> (tuple) { 
      (tuple.is_a?(Array) && tuple.size == 2) or 
        raise Error.new(location, "Not a tuple: #{tuple}")

      [:raw, tuple[@index], @scope, location]
    })

    [:noop, nil, @scope, location]
  end
end
