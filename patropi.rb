require_relative './lib/interpreter'

# Read from stdin until EOF
input = ""

while line = STDIN.gets
  input += line
end

# Run the interpreter
Interpreter.run(input)
