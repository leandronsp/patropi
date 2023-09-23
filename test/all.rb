#RubyVM::InstructionSequence.compile_option = { tailcall_optimization: true }

# frozen_string_literal: true

Dir['./test/*.rb'].sort.each { |file| require file }
