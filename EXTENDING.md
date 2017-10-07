### View Subclass Example

``` ruby
class MyView < Grrr::View
	attr_reader :my_property

	def initialize(parent, origin, num_cols=nil, num_rows=nil, enabled=true, my_property=true)
		# invoke superclass constructor
		super(parent, origin, num_cols, num_rows, enabled)

		# save any custom properties
		@my_property = my_property

		# setup hooks
		@is_lit_at_func = lambda { |point|
			# function that should return true if led at point is lit, otherwise false
		}
		@view_button_state_changed_action = lambda { |point, pressed|
			# handle press / release

			# if press / release results should result in a new value call
			# value_action to set value and notify any observing objects
			self.value_action=(new_value)

		}
	end

	# add custom class methods for instantiation here
	def self.new_my_property_false(parent, origin, num_cols=nil, num_rows=nil)
		new(parent, origin, num_cols, num_rows, true, false)
	end

	# add custom methods here
end
```

### Controller Subclass Example

``` ruby
class MyGridController < Grrr::Controller
	def initialize(arg1, arg2, view, origin, create_top_view_if_none_is_supplied=true)
		super(8, 7, view, origin, create_top_view_if_none_is_supplied) # pass num_cols, num_rows view and origin to superclass and basic bounds will be set up aswell as attachment to view (if view is supplied)

		# setup hook to trigger buttons
		# emit_button_event

		# refresh controller as last thing in initialize to refresh leds
		refresh
	end

	# it is good practice to override new_detached with custom arguments to ensure it is 
	# possible to create an instance of the controller that is not attached to any view
	def self.new_detached(arg1, arg2)
		new(arg1, arg2, nil, nil, false)
	end

	def handle_view_led_refreshed_event(point, on)
		# send update-led-message to device
	end

	def handle_view_button_state_changed_event(point, pressed)
		# may be used if you want to indicate button state in controller
		# example: in ScreenGrid button borders appear around ScreenGridButtons
	end

	def to_s
		# optionally return a descriptive string representation
		"My Grid Controller connected to port #{arg1} (#{@num_cols}x#{@num_rows})"
	end
end
```
