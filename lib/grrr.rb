require 'scext'

module Grrr
	def validate_using_jruby
		raise "this feature is only available when running jruby" unless using_jruby?
	end
end

%w{common view button abstract_toggle toggle v_toggle h_toggle keyboard container_view top_view switcher controller multi_button_view multi_toggle_view}.each do |s|
	require "grrr/#{s}"
end

if using_jruby? # TODO: refactoring this into the screen_grid_button and screen_grid classes themselves
	require 'java'
	%w{screen_grid_button screen_grid}.each do |s|
		require "grrr/#{s}"
	end
else
	puts "warning: screengrid classes are not loaded since they require jruby." unless defined?(GRRR_DO_NOT_POST_JRUBY_WARNINGS)
end

require 'unstable.rb'
