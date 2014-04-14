require 'test/unit'

testdir = File.expand_path('.')
libdir = File.expand_path('../lib')
[testdir, libdir].each { |path| $LOAD_PATH.unshift(path) unless $LOAD_PATH.include?(path) }

require 'test_helper'

GRRR_DO_NOT_POST_JRUBY_WARNINGS = true

require 'grrr'

%w{view container_view}.each do |s|
	require "grrr_ruby/#{s}_test"
end
