# frozen_string_literal: true

require_relative '../lib/ext'
require_relative '../lib/error'
require_relative '../lib/trampoline'
require_relative '../lib/interpreter'

Dir['./test/*.rb'].sort.each { |file| require file }
