require 'test/unit'

testdir = File.expand_path('.')
libdir = File.expand_path('../lib')
[testdir, libdir].each { |path| $LOAD_PATH.unshift(path) unless $LOAD_PATH.include?(path) }

require 'test_helper'

GRRR_DO_NOT_POST_JRUBY_WARNINGS = true

require 'grrr'
require 'mock_grrr'

%w{view button toggle container_view top_view controller keyboard switcher multi_button_view multi_toggle_view}.each do |s|
	require "grrr/#{s}_test"
end
