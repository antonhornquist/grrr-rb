require 'test/unit'

require File.expand_path('../test_helper', __FILE__)

GRRR_DO_NOT_POST_JRUBY_WARNINGS = true

require 'grrr'

%w{view container_view}.each do |s|
	require File.expand_path("../grrr_ruby/#{s}_test", __FILE__)
end
