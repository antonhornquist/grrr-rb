require 'test/unit'

class Test::Unit::TestCase
	def self.test(name, &block)
		test_name = "test: #{name} ".to_sym
		defined = instance_method(test_name) rescue false
		raise "#{test_name} is already defined in #{self}" if defined
		define_method(test_name, &block)
	end
end

def save_globals
	$SAVED_GRID_CONTAINER_VIEW_FLASH_ADDED_REMOVED = $GRRR_FLASH_ADDED_REMOVED
	$SAVED_GRID_VIEW_TRACE_PRESSED = $GRRR_OUTPUT_TRACE_PRESSED
	$SAVED_GRID_VIEW_TRACE_LED = $GRRR_OUTPUT_TRACE_LED
end

def disable_trace_and_flash
	$GRRR_FLASH_ADDED_REMOVED = false
	$GRRR_OUTPUT_TRACE_PRESSED = false
	$GRRR_OUTPUT_TRACE_LED = false
end

def restore_globals
	$GRRR_FLASH_ADDED_REMOVED = $SAVED_GRID_CONTAINER_VIEW_FLASH_ADDED_REMOVED
	$GRRR_OUTPUT_TRACE_PRESSED = $SAVED_GRID_VIEW_TRACE_PRESSED
	$GRRR_OUTPUT_TRACE_LED = $SAVED_GRID_VIEW_TRACE_LED
end
