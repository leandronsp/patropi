class Evaluators::Tuple 
  def self.evaluate(*args) = new(*args).evaluate

  def initialize(data, scope, terms, executors)
    @data = data
    @scope = scope
    @terms = terms
    @executors = executors
  end

  def evaluate
    first, second, location = @data.values_at(:first, :second, :location)

    @executors.push(-> (first) {
      @executors.push(-> (second) {
        [:raw, [first, second], @scope, location]
      })

      [:noop, nil, @scope, location]
    })

    @terms.push(second, first)

    [:noop, nil, @scope, location]
  end
end
