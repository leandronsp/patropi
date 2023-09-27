module Evaluators
  class Base
    def initialize(terms, executors)
      @terms = terms
      @executors = executors
    end

    def evaluate(term, scope, location)
      case term
      in { kind: 'Bool', **data }; [:raw, data[:value],       scope, data[:location]]
      in { kind: 'Int',  **data }; [:raw, data[:value].to_i,  scope, data[:location]]
      in { kind: 'Str',  **data }; [:raw, data[:value].to_s,  scope, data[:location]]
      in { kind: 'Var',  **data }; [:raw, scope[data[:text]], scope, data[:location]]

      in { kind: 'Print',    **data }; do_print(data, scope)
      in { kind: 'Binary',   **data }; do_binary(data, scope)
      in { kind: 'Let',      **data }; do_let(data, scope)
      in { kind: 'If',       **data }; do_if(data, scope)
      in { kind: 'Function', **data }; do_function(data, scope)
      in { kind: 'Call',     **data }; do_call(data, scope)
      in { kind: 'Tuple',    **data }; do_tuple(data, scope)
      in { kind: 'First',    **data }; do_tuple_access(data, scope, 0)
      in { kind: 'Second',   **data }; do_tuple_access(data, scope, 1)

      else raise Error.new(location, "Unknown term: #{term}")
      end
    end

    def do_print(data, scope)
      Evaluators::Print.evaluate(data, scope, @terms, @executors)
    end
    
    def do_let(data, scope)
      Evaluators::Let.evaluate(data, scope, @terms, @executors)
    end

    def do_if(data, scope)
      Evaluators::If.evaluate(data, scope, @terms, @executors)
    end

    def do_function(data, scope)
      Evaluators::Function.evaluate(data, scope, @terms, @executors)
    end

    def do_tuple(data, scope)
      Evaluators::Tuple.evaluate(data, scope, @terms, @executors)
    end

    def do_tuple_access(data, scope, index)
      Evaluators::TupleAccess.evaluate(data, scope, @terms, @executors, index)
    end

    def do_call(data, scope)
      Evaluators::Call.evaluate(data, scope, @terms, @executors)
    end

    def do_binary(data, scope)
      Evaluators::Binary.evaluate(data, scope, @terms, @executors)
    end
  end
end
