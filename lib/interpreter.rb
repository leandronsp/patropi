class Interpreter 
  def self.run(*args) = new.run(*args)

  def initialize
    @terms     = []
    @executors = []

    @trampoline = Trampoline.new(@terms, @executors)
    @evaluator  = Evaluators::Base.new(@terms, @executors)
  end

  def run(json_input)
    JSON
      .parse(json_input, symbolize_names: true)
      .then { |data| data[:expression] }
      .then(&@terms.method(:push))

    @trampoline.run do |term, scope, location|
      @evaluator.evaluate(term, scope, location)
    end
  end
end
