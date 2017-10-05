# grrr-rb

Grid controller UI toolkit for Ruby.

## Description

The grrr-rb library provides high level UI abstractions for grid based controllers simplifying interaction with for instance [monome](http://monome.org) 40h, 64, 128 and 256 grid devices. This library is built atop of and thus depends on [serialoscclient-rb](http://github.com/antonhornquist/serialoscclient-rb).

## Usage

Download serialoscclient-rb. Place it in a folder adjacent to the grrr-rb folder. Add the lib folder of grrr-rb to the Ruby load path and ```require 'grrr'```. If grrr-rb is run in JRuby ```require 'grrr/screengrid'``` will make fake screengrid available for use.

TODO: this will eventually become a ruby gem

## Examples

### Monome Example

``` ruby
require 'monome'
a=Monome64.new("test")

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
require 'grrr/screen_grid' # only available for JRuby

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
require 'grrr/screen_grid' # only available for JRuby

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

## Documentation

Schelp documentation available for the [Grrr-sc](http://github.com/antonhornquist/Grrr-sc) SuperCollider library is applicable to this Ruby version of the library.

## Implementation

This is a Ruby port of my SuperCollider library [Grrr-sc](http://github.com/antonhornquist/Grrr-sc).

The SuperCollider and Ruby classes are generated using the [rsclass-rb](http://github.com/antonhornquist/rsclass-rb) class generator based on meta data defined in the [grrr-meta-rb](http://github.com/antonhornquist/grrr-meta-rb) repository.

For low latency real-time Grid controller performance working with Grrr-sc and SuperCollider is recommended.

If you intend to use this library beware of the monkey patching in file lib/scext.rb containing a collection of SuperCollider extensions ported to Ruby.

## Classes

Classes in this library reside in the Grrr module.

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
			* StepView - A grid of buttons of the same size indexed as steps with possibility to indicate playing step. Suitable for step sequencing.

		* MultiToggleView - An array of vertical or horizontal toggles of the same size.
* Controller - Abstract superclass. Represents a device that may attach to and control part of or an entire view.
	* Monome - Abstract class for [monome](http://monome.org) controllers.
		* Monome64 - An 8x8 monome.
		* MonomeV128 - An 8x16 monome.
		* MonomeH128 - A 16x8 monome.
		* Monome256 - An 8x16 monome.
	* ScreenGrid - An on-screen controller of user definable size. Button events may be triggered with mouse and keyboard. Only available for JRuby since it depends on Java GUI. Use ```require 'grrr/screengrid'```

## Extending Grrr

TODO

## Requirements

This library requires [serialoscclient-rb](http://github.com/antonhornquist/serialoscclient-rb).

This code has been developed and tested in Ruby 2.3.3 and JRuby 9.1.6.0. ```Grrr::ScreenGrid``` only works for JRuby.

## License

Copyright (c) Anton Hörnquist
