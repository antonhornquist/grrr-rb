# grrr-rb

Grid controller UI widget library for Ruby targeting the JRuby platform

## Description

This is a Ruby port of my SuperCollider library Grrr-sc targeting the JRuby platform. It requires scext-rb. The Ruby version primarily exists to run test suites from the command prompt and to explore the commonalities between SuperCollider and Ruby. For real-time performances one should probably go SuperCollider and use Grrr-sc.

## Examples

### Example 1

a = ScreenGrid.new

b = GridButton.new(a, "0@0")
b.action = lambda { |value| puts "the first button's value was changed to #{value}!" }

c = GridButton.new_momentary(a, "1@1", 2, 2)
c.action = lambda { |value| puts "the second button's value was changed to #{value}!" }

a.remove_all

# Example 2

b = GridButton.new_decoupled(a, "0@0")
b.button_pressed_action = lambda { puts "the first button was pressed!" }
b.button_released_action = lambda { puts "the first button was released!" }


## License

Copyright (c) Anton Hörnquist
