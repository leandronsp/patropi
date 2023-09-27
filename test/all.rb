# frozen_string_literal: true

require 'test/unit'
require 'json'

require_relative '../lib/ext'
require_relative '../lib/error'

require_relative '../lib/lexer'
require_relative '../lib/parser'

require_relative '../lib/evaluators'
require_relative '../lib/trampoline'
require_relative '../lib/interpreter'

Dir['./test/*.rb'].sort.each { |file| require file }
