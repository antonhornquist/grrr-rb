# grrr-rb

Grid controller UI toolkit for Ruby.

## Description

This is a **less maintained** port of the [Grrr-sc](http://github.com/antonhornquist/Grrr-sc) SuperCollider library. Please report bugs.

The grrr-rb library provides high level UI abstractions for grid based controllers such as [monome](http://monome.org) 40h, 64, 128 and 256 devices. Widgets, ie. buttons and toggles, are placed on controllers. Widgets can be nested in containers which allows for modes and paging. The library adheres to principles of the standard GUI class library in SuperCollider.

## Usage

Grrr can be used as a framework for building full featured apps or in live coding.

Requiring ```require 'grrr'``` includes the Grrr module containing the classes described below.

If Grrr is run in JRuby ```require 'grrr/screengrid'``` will make a virtual on-csreen grid available for use.

## Examples

### Building a UI in IRB

This assumes a monome grid is connected to the computer.

```
$ cd /path/to/grrr-rb
$ rake irb
irb> monome=Grrr::Monome.new
SerialOSC Devices:
  x y z
irb> steps=Grrr::StepView.new(monome, Grrr::Point.new(0, 0), monome.num_cols, 1)
irb> Thread.new do
irb>   i = 0
irb>   while true
irb>     steps.playhead = i
irb>     puts (steps.step_value(i) ? "ho!" : "hey" )
irb>     sleep 0.5
irb>     i = (i + 1) % monome.num_cols
irb>   end
irb> end
```

### Hello World

``` ruby
require 'grrr'

a=Grrr::Monome.new("test")
b=Grrr::Button.new(a, Grrr::Point.new(0, 0)) # places a 1x1 button at top left key
b.action = lambda { |button, value| puts "#{value ? "Hello", "Goodbye"} World" }

# pressing the top left grid button of the grid will change led state and output to the Post Window

gets # wait for enter to quit
```

### A Simple Step Sequencer

``` ruby
a=Grrr::Monome.new # creates a monome
b=Grrr::StepView.new(a, Grrr::Point.new(0, 7), a.num_cols, 1) # the step view defines when to play notes 
c=Grrr::MultiToggleView.new(a, Grrr::Point.new(0, 0), a.num_cols, 7) # toggles representing note pitch
c.values_are_inverted=true

# sequence that posts a degree for steps that are lit
Thread.new do
  i = 0
  while true
    b.playhead = i
    if b.get_step_value(i)
      puts "degree: #{c.toggle_value(b.playhead)}"
    end
    sleep 0.15
    i = (i + 1) % a.num_cols
  end
end

# randomize pattern
b.num_cols.times do |index|
	c.set_toggle_value(index, (c.num_rows).rand)
	b.set_step_value(index, [true, false].choose)
end

gets # wait for enter to quit
```

## Requirements

This grrr-rb library requires [serialoscclient-rb](http://github.com/antonhornquist/serialoscclient-rb). The library has been developed and tested in Ruby 2.3.3 and JRuby 9.1.6.0. ```Grrr::ScreenGrid``` only works for JRuby due to its reliance on Java GUI.

## Installation

Download and install dependency [serialoscclient-rb](http://github.com/antonhornquist/serialoscclient-rb). Place it in a folder adjacent to the grrr-rb folder.

Download grrr-rb. Add the ```lib``` folder of grrr-rb to the Ruby load path.

## Documentation

No Ruby specific documentation is available. Schelp documentation available for the [Grrr-sc](http://github.com/antonhornquist/Grrr-sc) SuperCollider library is applicable to this version of the library. Be aware, however, that in contrast to Grrr-sc methods in grrr-rb are snake_case.

## Tests

An automated test suite is included. Just execute:

```
$ rake
```

## Implementation

This is a Ruby port of my SuperCollider library [Grrr-sc](http://github.com/antonhornquist/Grrr-sc).

The SuperCollider and Ruby classes are generated using the [rsclass-rb](http://github.com/antonhornquist/rsclass-rb) class generator based on meta data defined in the [grrr-meta-rb](http://github.com/antonhornquist/grrr-meta-rb) repository.

For low latency real-time Grid controller performance working with Grrr-sc and SuperCollider is recommended.

Code readability has been favored over optimizations.

If you intend to use this library beware of monkey patching (```lib/core_extensions/*```) due to port of a collection of required SuperCollider extensions to Ruby.

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
	* Monome - Generic [Monome](http://monome.org) controller.
		* Monome64 - 8x8 monome.
		* MonomeV128 - 8x16 monome.
		* MonomeH128 - 16x8 monome.
		* Monome256 - 16x16 monome.
	* ScreenGrid - An on-screen controller of user definable size. Button events may be triggered with mouse and keyboard. Only available for JRuby since it depends on Java GUI. Use ```require 'grrr/screengrid'```

## Extending Grrr

Section "Extending Grrr" in the Schelp documentation available for the [Grrr-sc](http://github.com/antonhornquist/Grrr-sc) is applicable to this version of the library. In contrast to Grrr-sc methods in grrr-rb are snake_case.

## License

Copyright (c) Anton Hörnquist
