require 'point'
require 'core_extensions/array/fill'
require 'core_extensions/nil_class/to_point'
require 'core_extensions/string/to_point'
require 'core_extensions/symbol/setter_getter'

NilClass.include CoreExtensions::NilClass::ToPoint
String.include CoreExtensions::String::ToPoint
Symbol.include CoreExtensions::Symbol::SetterGetter

module Grrr
end

%w{common view button abstract_toggle toggle v_toggle h_toggle keyboard container_view top_view controller multi_button_view multi_toggle_view step_view monome monome_64 v_monome_128 h_monome_128 monome_256}.each do |s|
	require "grrr/#{s}"
end

require 'unstable.rb'
