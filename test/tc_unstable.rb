require 'test/unit'

require File.expand_path('../test_helper', __FILE__)

GRRR_DO_NOT_POST_JRUBY_WARNINGS = true

require 'grrr'

require File.expand_path('../mock_grrr', __FILE__)
require File.expand_path('../mock_unstable', __FILE__)

=begin
%w{}.each do |s|
	require File.expand_path("../unstable/#{s}_test", __FILE__)
end
=end
