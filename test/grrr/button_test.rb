class TestButton < Test::Unit::TestCase
	def setup
		save_globals
		disable_trace_and_flash
	end

	def teardown
		restore_globals
	end

	# initialization
	test "a button should by default be a released coupled toggle button with value false" do
		button = Grrr::Button.new_detached
		assert(button.is_released?)
		assert(button.is_coupled?)
		assert_equal(:toggle, button.behavior)
		assert_equal(false, button.value)
	end

	test "it should be possible to set a buttons behavior to momentary" do
		button = Grrr::Button.new_detached
		button.behavior = :momentary
		assert_equal(:momentary, button.behavior)
	end

	test "it should be possible to create a momentary button from scratch" do
		button = Grrr::Button.new_momentary(nil, nil, 1, 1)
		assert_equal(:momentary, button.behavior)
	end

	test "it should be possible to decouple a button" do
		button = Grrr::Button.new_detached
		button.coupled = false
		assert_equal(false, button.is_coupled?)
	end

	test "it should be possible to create a decoupled button from scratch" do
		button = Grrr::Button.new_decoupled(nil, nil, 1, 1)
		assert_equal(false, button.is_coupled?)
	end

	# button pressed state and button events
	test "a single view button press event should make a button pressed" do
		button = Grrr::Button.new_detached(1, 1)
		button.press(Grrr::Point.new(0, 0))
		assert(button.is_pressed?)
	end

	test "a button should not be considered released until all view buttons are released" do
		button = Grrr::Button.new_detached(2, 2)

		button.press(Grrr::Point.new(0, 0))

		assert(button.is_pressed?)

		button.press(Grrr::Point.new(1, 0))

		assert(button.is_pressed?)

		button.release(Grrr::Point.new(0, 0))

		assert(button.is_pressed?)

		button.release(Grrr::Point.new(1, 0))

		assert(button.is_released?)
	end

	test "when pressed state of a button is updated button pressed and released actions should be triggered" do
		button = Grrr::Button.new_decoupled(nil, nil, 2, 2)
		pressed_listener = MockButtonPressedListener.new(button)
		released_listener = MockButtonReleasedListener.new(button)

		button.press(Grrr::Point.new(0, 0))
		assert( pressed_listener.has_been_notified_of?( [ [button] ] ) )

		button.press(Grrr::Point.new(1, 0))
		assert( pressed_listener.has_been_notified_of?( [ [button] ] ) )

		button.release(Grrr::Point.new(0, 0))
		assert( released_listener.has_not_been_notified_of_anything? )

		button.release(Grrr::Point.new(1, 0))
		assert( released_listener.has_been_notified_of?( [ [button] ] ) )
	end

	# led events and refresh
	test "when the value of a button is set to true leds are lit" do
		button = Grrr::Button.new_detached(2, 2)
		button.id = :abc
		view_led_refreshed_listener = MockViewLedRefreshedListener.new(button)

		button.value = true

		assert(
			view_led_refreshed_listener.has_been_notified_of?(
				[
					{ :source => :abc, :point => Grrr::Point.new(0, 0), :on => true },
					{ :source => :abc, :point => Grrr::Point.new(1, 0), :on => true },
					{ :source => :abc, :point => Grrr::Point.new(0, 1), :on => true },
					{ :source => :abc, :point => Grrr::Point.new(1, 1), :on => true },
				]
			)
		)
	end

	test "when the value of a button is set to false leds are unlit" do
		button = Grrr::Button.new_detached(2, 2)
		button.id = :abc
		button.value = true
		view_led_refreshed_listener = MockViewLedRefreshedListener.new(button)

		button.value = false

		assert(
			view_led_refreshed_listener.has_been_notified_of?(
				[
					{ :source => :abc, :point => Grrr::Point.new(0, 0), :on => false },
					{ :source => :abc, :point => Grrr::Point.new(1, 0), :on => false },
					{ :source => :abc, :point => Grrr::Point.new(0, 1), :on => false },
					{ :source => :abc, :point => Grrr::Point.new(1, 1), :on => false },
				]
			)
		)
	end

	# decoupled button behavior
	test "a decoupled button should not toggle value nor trigger main action when it is pressed and when it is released" do
		button = Grrr::Button.new_decoupled(nil, nil, 2, 2)
		action_listener = MockActionListener.new(button)

		assert_equal(false, button.value)
		button.press(Grrr::Point.new(0, 0))
		assert_equal(false, button.value)
		button.release(Grrr::Point.new(0, 0))
		assert_equal(false, button.value)

		assert( action_listener.has_not_been_notified_of_anything? )
	end

	# coupled toggle button behavior
	test "a coupled toggle button should toggle value every time the button is pressed" do
		button = Grrr::Button.new_detached(1, 1)

		button.press(Grrr::Point.new(0, 0))
		assert_equal(true, button.value)
		button.release(Grrr::Point.new(0, 0))
		assert_equal(true, button.value)
		button.press(Grrr::Point.new(0, 0))
		assert_equal(false, button.value)
		button.release(Grrr::Point.new(0, 0))
		assert_equal(false, button.value)
	end

	test "a coupled toggle button should trigger the main action every time a button is pressed" do
		button = Grrr::Button.new_detached(1, 1)
		action_listener = MockActionListener.new(button)

		button.press(Grrr::Point.new(0, 0))

		assert(
			action_listener.has_been_notified_of?(
				[
					[button, true]
				]
			)
		)

		button.release(Grrr::Point.new(0, 0))

		assert(
			action_listener.has_been_notified_of?(
				[
					[button, true]
				]
			)
		)

		button.press(Grrr::Point.new(0, 0))

		assert(
			action_listener.has_been_notified_of?(
				[
					[button, true],
					[button, false]
				]
			)
		)

		button.release(Grrr::Point.new(0, 0))

		assert(
			action_listener.has_been_notified_of?(
				[
					[button, true],
					[button, false]
				]
			)
		)
	end

	# coupled momentary button behavior
	test "a coupled momentary button should toggle value both when button is pressed and when it is released" do
		button = Grrr::Button.new_momentary(nil, nil, 1, 1)

		button.press(Grrr::Point.new(0, 0))
		assert_equal(true, button.value)
		button.release(Grrr::Point.new(0, 0))
		assert_equal(false, button.value)

		button.value=true

		button.press(Grrr::Point.new(0, 0))
		assert_equal(false, button.value)
		button.release(Grrr::Point.new(0, 0))
		assert_equal(true, button.value)
	end

	test "a coupled momentary button should trigger main action both when button is pressed and when it is released" do
		button = Grrr::Button.new_momentary(nil, nil, 1, 1)
		action_listener = MockActionListener.new(button)

		button.press(Grrr::Point.new(0, 0))

		assert(
			action_listener.has_been_notified_of?(
				[
					[button, true]
				]
			)
		)

		button.release(Grrr::Point.new(0, 0))

		assert(
			action_listener.has_been_notified_of?(
				[
					[button, true],
					[button, false]
				]
			)
		)

		button.value=true

		button.press(Grrr::Point.new(0, 0))

		assert(
			action_listener.has_been_notified_of?(
				[
					[button, true],
					[button, false],
					[button, false]
				]
			)
		)

		button.release(Grrr::Point.new(0, 0))

		assert(
			action_listener.has_been_notified_of?(
				[
					[button, true],
					[button, false],
					[button, false],
					[button, true]
				]
			)
		)

	end
end
