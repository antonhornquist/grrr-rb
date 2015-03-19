# grrr-rb

Grid controller UI widget library for Ruby targeting the JRuby platform

## Description

High level UI abstractions for grid based controllers. Simplifies interaction with for instance Monome devices.

This is a Ruby port of my SuperCollider library Grrr-sc targeting the JRuby platform. It requires scext-rb. The Ruby version was created to explore commonalities of SuperCollider and Ruby. For real-time performances one should probably go SuperCollider and use Grrr-sc.

## Examples

### Example 1

``` ruby
require 'grrr'
a = ScreenGrid.new

b = GridButton.new(a, "0@0")
b.action = lambda { |value| puts "the first button's value was changed to #{value}!" }

# press top-leftmost screen grid button to test the first button

c = GridButton.new_momentary(a, "1@1", 2, 2)
c.action = lambda { |value| puts "the second button's value was changed to #{value}!" }

# press screen grid button anywhere at 1@1 to 2@2 to test the second button

a.view.remove_all_children
```

### Example 2

``` ruby
b = GridButton.new_decoupled(a, "0@0")
b.button_pressed_action = lambda { puts "the first button was pressed!" }
b.button_released_action = lambda { puts "the first button was released!" }

# press top-leftmost screen grid button to test the button

a.view.remove_all_children
```

### Example 3

``` ruby
```

## Classes

* View - Abstract superclass. Represents a 2D grid of backlit buttons.
	* Button - A button that may span over several rows and columns.
	* AbstractToggle
		* Toggle
			* VToggle
			* HToggle
		* (AbstractRangeToggle (rename to RangeToggleBase?))
			* (VRangeToggle)
			* (HRangeToggle)
		* (SliderBase)
			* (VSlider)
			* (HSlider)
	* Keyboard
	* ContainerView - Abstract class for views that may contain other views.
		* TopView - This is the topmost view in a view tree and typically the view to which controllers attach. The view cannot be added as a child to any other view.
		* MultiButtonView - A grid of buttons of the same size.

		* MultiToggleView - An array of vertical or horizontal toggles of the same size.
		* Switcher - A container that only have one child view active at any given time. Has convenience methods for changing which child view is active.
* Controller - Abstract superclass. Represents a device that may attach to and control part of or an entire view.
	* ScreenGrid - An on-screen controller of user definable size. Button events may be triggered with mouse and keyboard.
	* (AbstractMonome - Superclass for all monomes.)
		* (Monome40h - monome 40h.)
		* (Monome64 - monome 64.)
		* (Monome128 - monome 128.)
		* (Monome256 - monome 256.)
	* (MPC500 - An Akai MPC 500.)

## Extending Grrr

### View Subclass Example

``` ruby
class MyView < GridView
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
class MyGridController < GridController
	def initialize(arg1, arg2, view, origin, create_top_view_if_none_is_supplied=true)
		super(8, 7, view, origin, create_top_view_if_none_is_supplied) # pass num_cols, num_rows view and origin to superclass and basic bounds will be set up aswell as attachment to view (if view is supplied)

		# setup hook to trigger buttons
		# emit_button_event

		# refresh controller as last thing in initialize to refresh leds
		refresh
	end

	# it is good form to override new_detached with custom arguments to ensure it is 
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

	def info
		# optionally return a description on how to setup physical device. example:
		"Connect My Grid Controller by USB and configure it to send button press / release osc messages to port #{arg1}"
	end
end
```

## License

Copyright (c) Anton Hörnquist
