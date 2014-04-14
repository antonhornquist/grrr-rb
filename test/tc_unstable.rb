require 'test/unit'

testdir = File.expand_path('.')
libdir = File.expand_path('../lib')
[testdir, libdir].each { |path| $LOAD_PATH.unshift(path) unless $LOAD_PATH.include?(path) }

require 'test_helper'

GRRR_DO_NOT_POST_JRUBY_WARNINGS = true

require 'grrr'
require 'mock_grrr'
require 'mock_unstable'

=begin
%w{}.each do |s|
	require "unstable/#{s}_test"
end
=end
