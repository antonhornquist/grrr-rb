module Grrr
	INDICATE_ADDED_REMOVED_ATTACHED_DETACHED = false
	TRACE_BUTTON_EVENTS = false
	TRACE_LED_EVENTS = false

	def validate_using_jruby
		raise "this feature is only available when running jruby" unless using_jruby?
	end
end
