require 'json'

require_relative 'lib/ext'
require_relative 'lib/error'

require_relative 'lib/evaluators'
require_relative 'lib/trampoline'
require_relative 'lib/interpreter'

# Read from stdin until EOF
input = ""

while line = STDIN.gets
  input += line
end

# Run the interpreter
Interpreter.run(input)
