class Grrr::Common
	class << self
		attr_accessor :indicate_added_removed_attached_detached
		attr_accessor :trace_button_events
		attr_accessor :trace_led_events
	end

	def self.validate_using_jruby
		raise "this feature is only available when running jruby" unless using_jruby?
	end
end
