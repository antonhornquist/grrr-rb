require 'test/unit'

require File.expand_path('../test_helper', __FILE__)

require 'grrr'

require File.expand_path('../mock_grrr', __FILE__)

%w{view button toggle container_view top_view controller keyboard multi_button_view multi_toggle_view}.each do |s|
	require File.expand_path("../grrr/#{s}_test", __FILE__)
end
