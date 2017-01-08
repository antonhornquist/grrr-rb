require 'scext'

module Grrr
	def validate_using_jruby
		raise "this feature is only available when running jruby" unless using_jruby?
	end
end

%w{common view button abstract_toggle toggle v_toggle h_toggle keyboard container_view top_view switcher controller multi_button_view multi_toggle_view screen_grid_button screen_grid}.each do |s|
	require "grrr/#{s}"
end

require 'unstable.rb'
