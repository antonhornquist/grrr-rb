require 'core_extensions/array/fill'
require 'core_extensions/string/to_point'
require 'core_extensions/symbol/setter_getter'

String.include CoreExtensions::String::ToPoint
Symbol.include CoreExtensions::Symbol::SetterGetter

module Grrr
end

%w{point common view button abstract_toggle toggle v_toggle h_toggle keyboard container_view top_view controller multi_button_view multi_toggle_view step_view monome monome_64 v_monome_128 h_monome_128 monome_256}.each do |s|
	require "grrr/#{s}"
end
