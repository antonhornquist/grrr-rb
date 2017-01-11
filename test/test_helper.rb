require 'test/unit'

def save_globals
	$SAVED_INDICATE_ADDED_REMOVED_ATTACHED_DETACHED_FLAG = Grrr::Common.indicate_added_removed_attached_detached
	$SAVED_TRACE_BUTTON_EVENTS_FLAG = Grrr::Common.trace_button_events
	$SAVED_TRACE_LED_EVENTS_FLAG = Grrr::Common.trace_led_events
end

def disable_trace_and_flash
	Grrr::Common.indicate_added_removed_attached_detached = false
	Grrr::Common.trace_button_events = false
	Grrr::Common.trace_led_events = false
end

def restore_globals
	Grrr::Common.indicate_added_removed_attached_detached = $SAVED_INDICATE_ADDED_REMOVED_ATTACHED_DETACHED_FLAG
	Grrr::Common.trace_button_events = $SAVED_TRACE_BUTTON_EVENTS_FLAG
	Grrr::Common.trace_led_events = $SAVED_TRACE_LED_EVENTS_FLAG
end
