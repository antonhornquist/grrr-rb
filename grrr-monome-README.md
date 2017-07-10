# grrr-monome-rb

Monome support for the grrr-rb UI toolkit.

## Description

grrr-monome-rb makes the [grrr-rb](http://github.com/antonhornquist/grrr-rb) grid controller UI toolkit support monome devices using the (old) MonomeSerial protocol.

## Usage

First, install required dependencies.

[osc-ruby](http://github.com/aberant/osc-ruby) is available as a gem:

```
$ gem install osc-ruby
```

Download [grrr-rb](http://github.com/antonhornquist/grrr-rb) and add the grrr-rb lib folder to the Ruby load path.

Next, add the grrr-monome-rb lib folder to the Ruby load path and ```require 'monome'```.

Run MonomeSerial configured with the following settings:

| Setting      | Value                             |
|--------------|-----------------------------------|
| I/O Protocol | OpenSound Control                 |
| Host Address | your_monome_instance.host_address |
| Host Port    | your_monome_instance.host_port    |
| Listen Port  | your_monome_instance.listen_port  |
| Prefix       | your_monome_instance.prefix       |


Optionally, install EventMachine. It is available as a gem:

```
$ gem install eventmachine
```

If EventMachine is installed the the osc-ruby OSC::EMServer is used. If not, OSC::Server is used. I believe OSC::EMServer is faster than OSC::Server.

## Examples

### Example 1

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

## Requirements

This library requires [grrr-rb](http://github.com/antonhornquist/grrr-rb) and [osc-ruby](http://github.com/aberant/osc-ruby).

An optional dependency is [eventmachine](https://github.com/eventmachine/eventmachine).

This code has been developed and tested in Ruby 2.3.3.

## License

Copyright (c) Anton Hörnquist
