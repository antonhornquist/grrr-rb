scext_libdir=ENV['JAH_SCEXT_RB_DEV_DIR'] + '/lib'
$LOAD_PATH.unshift scext_libdir unless $LOAD_PATH.include?(scext_libdir )
require 'scext'

%w{grrr view button abstract_toggle toggle v_toggle h_toggle keyboard container_view top_view switcher controller multi_button_view multi_toggle_view}.each do |s|
	require "grrr/#{s}"
end

if using_jruby?
	require 'java'
	%w{screen_grid_button screen_grid key_grid}.each do |s|
		require "grrr/#{s}"
	end
else
	puts "warning: screengrid classes are not loaded since they require jruby." unless defined?(GRRR_DO_NOT_POST_JRUBY_WARNINGS)
end

require 'unstable.rb'
