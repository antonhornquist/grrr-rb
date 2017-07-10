# grrr-rb

Grid controller UI widget library for Ruby.

## Description

The grrr-rb library provides high level UI abstractions for grid based controllers simplifying interaction with for instance [monome](http://monome.org) 40h, 64, 128 and 256 grid devices.

## Usage

In order to use grrr-rb add its lib folder to the Ruby load path and ```require 'grrr'```. If grrr-rb is run in JRuby ```require 'grrr/screengrid'``` will make fake screengrid available for use.

First, install required dependencies.

The [osc-ruby](http://github.com/aberant/osc-ruby) library is available as a gem:

```
$ gem install osc-ruby
```

Optionally, install [eventmachine](https://github.com/eventmachine/eventmachine). It is also available as a gem:

```
$ gem install eventmachine
```

If eventmachine is installed the osc-ruby OSC::EMServer is used for monome communication. If not, OSC::Server is used.

The grrr-rb library currently support the legacy monome protocol. Run MonomeSerial configured with the following settings for it to work with grrr-rb:

| Setting      | Value                             |
|--------------|-----------------------------------|
| I/O Protocol | OpenSound Control                 |
| Host Address | your_monome_instance.host_address |
| Host Port    | your_monome_instance.host_port    |
| Listen Port  | your_monome_instance.listen_port  |
| Prefix       | your_monome_instance.prefix       |

## Examples

### Monome Example

``` ruby
require 'monome'
a=Monome64.new

b=Grrr::Button.new(a, "0@0")
b.action = lambda { |button, value| puts "button value was changed to #{value}!" }

c=Grrr::HToggle.new(a, "0@1")
c.action = lambda { |toggle, value| puts "toggle value was changed to #{value}!" }

d=Thread.new {
	while true
		c.value = (c.value+1) % 4
		sleep 0.5
	end
}

sleep 5
```

### Example 1

``` ruby
require 'grrr'
require 'grrr/screengrid' # only available for JRuby

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
require 'grrr'
require 'grrr/screengrid' # only available for JRuby

a = ScreenGrid.new

b = GridButton.new(a, "0@0")
b.action = lambda { |value| puts "the first button's value was changed to #{value}!" }

# press top-leftmost screen grid button to test the first button

c = GridButton.new_momentary(a, "1@1", 2, 2)
c.action = lambda { |value| puts "the second button's value was changed to #{value}!" }

# press screen grid button anywhere at 1@1 to 2@2 to test the second button

a.view.remove_all_children
```

### Example 3

``` ruby
b = GridButton.new_decoupled(a, "0@0")
b.button_pressed_action = lambda { puts "the first button was pressed!" }
b.button_released_action = lambda { puts "the first button was released!" }

# press top-leftmost screen grid button to test the button

a.view.remove_all_children
```

## Implementation

This is a Ruby port of my SuperCollider library Grrr-sc initially created to explore commonalities of the SuperCollider SCLang and Ruby programming languages.

For low latency real-time performances one should probably use SuperCollider and Grrr-sc.

If you intend to use this library beware of the monkey patching in file lib/scext.rb containing a collection of SuperCollider extensions ported to Ruby.

The SuperCollider and Ruby classes are generated using the [rsclass-rb](http://github.com/antonhornquist/rsclass-rb) class generator based on meta data defined in the [grrr-meta-rb](http://github.com/antonhornquist/grrr-meta-rb) repository.

## Classes

* View - Abstract superclass. Represents a 2D grid of backlit buttons.
	* Button - A button that may span over several rows and columns.
	* AbstractToggle - Abstract class for toggles.
		* Toggle - A toggle.
			* VToggle - Vertical toggle.
			* HToggle - Horizontal toggle.
	* Keyboard - A virtual keyboard.
	* ContainerView - Abstract class for views that may contain other views.
		* TopView - This is the topmost view in a view tree and typically the view to which controllers attach. The view cannot be added as a child to any other view.
		* MultiButtonView - A grid of buttons of the same size.

		* MultiToggleView - An array of vertical or horizontal toggles of the same size.
* Controller - Abstract superclass. Represents a device that may attach to and control part of or an entire view.
	* MonomeApp - Abstract class for [monome](http://monome.org) controller apps.
		* Monome64App - An 8x8 monome app.
		* MonomeV128App - An 8x16 monome app.
		* MonomeH128App - A 16x8 monome app.
		* Monome256App - An 8x16 monome app.
	* ScreenGrid - An on-screen controller of user definable size. Button events may be triggered with mouse and keyboard.

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

## Requirements

This library requires [osc-ruby](http://github.com/aberant/osc-ruby).

An optional dependency is [eventmachine](https://github.com/eventmachine/eventmachine).

This code has been developed and tested in Ruby 2.3.3 and JRuby 9.1.6.0. ```Grrr::ScreenGrid``` only works for JRuby.

## License

Copyright (c) Anton Hörnquist
