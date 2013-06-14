class TestToggle < Test::Unit::TestCase
	def setup
		save_globals
		disable_trace_and_flash
		@small_horizontal_toggle_4x1 = HToggle.new_detached(4, 1)
		@small_horizontal_toggle_4x1.id = :small_horizontal_toggle_4x1
		@large_horizontal_toggle_8x2 = HToggle.new_detached(8, 2)
		@large_horizontal_toggle_8x2.id = :large_horizontal_toggle_8x2
	end

	def teardown
		restore_globals
	end

	# initialization
	test "a toggle should by default be coupled and have value 0" do
		toggle = HToggle.new_detached
		assert(toggle.is_coupled?)
		assert_equal(0, toggle.value)
	end

	test "a horizontal toggle should by default be 4x1" do
		toggle = HToggle.new_detached
		assert_equal(4, toggle.num_cols)
		assert_equal(1, toggle.num_rows)
	end

	test "when only num cols is supplied on creation a horizontal toggle should get num rows 1" do
		toggle = HToggle.new_detached(8)
		assert_equal(1, toggle.num_rows)
	end

	test "a vertical toggle should by default be 1x4" do
		toggle = VToggle.new_detached
		assert_equal(1, toggle.num_cols)
		assert_equal(4, toggle.num_rows)
	end

	test "when only num rows is supplied on creation a vertical toggle should get num cols 1" do
		toggle = VToggle.new_detached(nil, 8)
		assert_equal(1, toggle.num_cols)
	end

	test "it should be possible to create a decoupled toggle from scratch" do
		toggle = HToggle.new_decoupled(nil, nil, 1, 1)
		assert_equal(false, toggle.is_coupled?)
	end

	test "it should be possible to create a nillable toggle from scratch" do
		toggle = HToggle.new_nillable(nil, nil, 1, 1)
		assert(toggle.is_nillable?)
	end

	# basic properties
	test "it should be possible to decouple a toggle" do
		toggle = HToggle.new_detached
		toggle.coupled = false
		assert_equal(false, toggle.is_coupled?)
	end

	test "it should be possible to make a toggle nillable" do
		toggle = HToggle.new_detached
		toggle.nillable = true
		assert(toggle.is_nillable?)
	end

	# toggle pressed state and toggle events
	test "a single view button press event should make a toggle pressed" do
		toggle = @small_horizontal_toggle_4x1
		toggle.press(Point.new(2, 0))
		assert(toggle.is_pressed?)
	end

	test "a toggle should not be considered released until all view buttons are released" do
		toggle = @small_horizontal_toggle_4x1

		toggle.press(Point.new(0, 0))

		assert(toggle.is_pressed?)

		toggle.press(Point.new(1, 0))

		assert(toggle.is_pressed?)

		toggle.release(Point.new(0, 0))

		assert(toggle.is_pressed?)

		toggle.release(Point.new(1, 0))

		assert(toggle.is_released?)
	end

	test "when pressed state of a toggle is updated toggle pressed and released actions should be triggered" do
		toggle = @small_horizontal_toggle_4x1
		pressed_listener = MockTogglePressedListener.new(toggle)
		released_listener = MockToggleReleasedListener.new(toggle)

		toggle.press(Point.new(0, 0))
		assert( pressed_listener.has_been_notified_of?( [ [toggle] ] ) )

		toggle.press(Point.new(1, 0))
		assert( pressed_listener.has_been_notified_of?( [ [toggle] ] ) )

		toggle.release(Point.new(0, 0))
		assert( released_listener.has_not_been_notified_of_anything? )

		toggle.release(Point.new(1, 0))
		assert( released_listener.has_been_notified_of?( [ [toggle] ] ) )
	end

	test "every view button press event on a toggle should trigger toggle value pressed action" do
		toggle = @small_horizontal_toggle_4x1
		toggle_value_pressed_listener = MockToggleValuePressedListener.new(toggle)

		toggle.press(Point.new(2, 0))

		assert(
			toggle_value_pressed_listener.has_been_notified_of?(
				[ [toggle, 2] ]
			)
		)

		toggle.press(Point.new(3, 0))

		assert(
			toggle_value_pressed_listener.has_been_notified_of?(
				[ [toggle, 2], [toggle, 3] ]
			)
		)

		toggle.press(Point.new(0, 0))

		assert(
			toggle_value_pressed_listener.has_been_notified_of?(
				[ [toggle, 2], [toggle, 3], [toggle, 0] ]
			)
		)
	end

	test "if several buttons get pressed on view and the min and max values of the pressed buttons get changed toggle range pressed action should be triggered" do
		toggle = @small_horizontal_toggle_4x1
		toggle_range_pressed_listener = MockToggleRangePressedListener.new(toggle)

		toggle.press(Point.new(1, 0))
		toggle.press(Point.new(3, 0))

		assert(
			toggle_range_pressed_listener.has_been_notified_of?(
				[ [toggle, [1, 3]] ]
			)
		)
	end

	# led events and refresh
	test "when a toggle is set to a new value leds should be refreshed and only the led corresponding to the value should be lit" do
		toggle = @small_horizontal_toggle_4x1
		view_led_refreshed_listener = MockViewLedRefreshedListener.new(toggle)

		toggle.value = 3

		assert(
			view_led_refreshed_listener.has_been_notified_of?(
				[
					{ :source => :small_horizontal_toggle_4x1, :point => Point.new(0, 0), :on => false },
					{ :source => :small_horizontal_toggle_4x1, :point => Point.new(1, 0), :on => false },
					{ :source => :small_horizontal_toggle_4x1, :point => Point.new(2, 0), :on => false },
					{ :source => :small_horizontal_toggle_4x1, :point => Point.new(3, 0), :on => true },
				]
			)
		)
	end

	test "when a nillable toggle is set to a nil value leds should be refreshed and all leds should be unlit" do
		toggle = @small_horizontal_toggle_4x1
		toggle.nillable=true
		view_led_refreshed_listener = MockViewLedRefreshedListener.new(toggle)

		toggle.value = nil

		assert(
			view_led_refreshed_listener.has_been_notified_of?(
				[
					{ :source => :small_horizontal_toggle_4x1, :point => Point.new(0, 0), :on => false },
					{ :source => :small_horizontal_toggle_4x1, :point => Point.new(1, 0), :on => false },
					{ :source => :small_horizontal_toggle_4x1, :point => Point.new(2, 0), :on => false },
					{ :source => :small_horizontal_toggle_4x1, :point => Point.new(3, 0), :on => false },
				]
			)
		)
	end

	test "if a non nillable toggle is set to a nil value an error should be thrown" do
		toggle = @small_horizontal_toggle_4x1
		view_led_refreshed_listener = MockViewLedRefreshedListener.new(toggle)

		assert_raise(RuntimeError) { toggle.value = nil }
	end

	# filled vs not filled
	test "a toggle that is not filled should only have the led correspoding to the current value lit" do
		toggle = HToggle.new_detached(4, 1)
		toggle.value = 2

		assert_equal(
			"  0 1 2 3      0 1 2 3\n" +
			"0 - - - -    0 - - L -\n",
			toggle.to_plot
		)
	end

	test "a filled toggle should have all leds up to the current value lit" do
		toggle = HToggle.new_detached(4, 1)
		toggle.filled = true
		toggle.value = 2

		assert_equal(
			"  0 1 2 3      0 1 2 3\n" +
			"0 - - - -    0 L L L -\n",
			toggle.to_plot
		)
	end

	test "when toggle is set filled all leds should automatically refresh" do
		toggle = @small_horizontal_toggle_4x1
		toggle.value = 2
		view_led_refreshed_listener = MockViewLedRefreshedListener.new(toggle)

		toggle.filled = true

		assert(
			view_led_refreshed_listener.has_been_notified_of?(
				[
					{ :source => :small_horizontal_toggle_4x1, :point => Point.new(0, 0), :on => true },
					{ :source => :small_horizontal_toggle_4x1, :point => Point.new(1, 0), :on => true },
					{ :source => :small_horizontal_toggle_4x1, :point => Point.new(2, 0), :on => true },
					{ :source => :small_horizontal_toggle_4x1, :point => Point.new(3, 0), :on => false },
				]
			)
		)
	end

	test "when toggle is set not filled all leds should automatically refresh" do
		toggle = @small_horizontal_toggle_4x1
		toggle.filled = true
		toggle.value = 2
		view_led_refreshed_listener = MockViewLedRefreshedListener.new(toggle)

		toggle.filled = false

		assert(
			view_led_refreshed_listener.has_been_notified_of?(
				[
					{ :source => :small_horizontal_toggle_4x1, :point => Point.new(0, 0), :on => false },
					{ :source => :small_horizontal_toggle_4x1, :point => Point.new(1, 0), :on => false },
					{ :source => :small_horizontal_toggle_4x1, :point => Point.new(2, 0), :on => true },
					{ :source => :small_horizontal_toggle_4x1, :point => Point.new(3, 0), :on => false },
				]
			)
		)
	end

	# thumb size
	test "a vertical toggle should by default have thumb width set to the width of its view" do
		toggle = VToggle.new_detached(2, 4)

		assert_equal(2, toggle.thumb_width)
	end

	test "a vertical toggle should by default have thumb height 1" do
		toggle = VToggle.new_detached(2, 4)

		assert_equal(1, toggle.thumb_height)
	end

	test "a horizontal toggle should by default have thumb width 1" do
		toggle = HToggle.new_detached(4, 2)

		assert_equal(1, toggle.thumb_width)
	end

	test "a horizontal toggle should by default have thumb height set to the height of its view" do
		toggle = HToggle.new_detached(4, 2)

		assert_equal(2, toggle.thumb_height)
	end

	test "it should be possible to change thumb width of a toggle" do
		toggle = HToggle.new_detached(4, 2)

		toggle.thumb_width = 2

		assert_equal(
			"  0 1 2 3      0 1 2 3\n" +
			"0 - - - -    0 L L - -\n" +
			"1 - - - -    1 L L - -\n",
			toggle.to_plot
		)
	end

	test "it should be possible to change thumb size of a toggle" do
		toggle = HToggle.new_detached(4, 2)

		toggle.thumb_size = [2, 2]

		assert_equal(
			"  0 1 2 3      0 1 2 3\n" +
			"0 - - - -    0 L L - -\n" +
			"1 - - - -    1 L L - -\n",
			toggle.to_plot
		)
	end

	test "it should be possible to change thumb height of a toggle" do
		toggle = HToggle.new_detached(4, 2)

		toggle.thumb_height = 1

		assert_equal(
			"  0 1 2 3      0 1 2 3\n" +
			"0 - - - -    0 L - - -\n" +
			"1 - - - -    1 - - - -\n",
			toggle.to_plot
		)
	end

	test "it should not be possible to set a toggle's thumb width to an inconsistent value" do
		toggle = HToggle.new_detached(4, 4)

		assert_raise(RuntimeError) { toggle.thumb_width = 3 }
	end

	test "it should not be possible to set a toggle's thumb height to an inconsistent value" do
		toggle = HToggle.new_detached(4, 4)

		assert_raise(RuntimeError) { toggle.thumb_height = 3 }
	end

	test "when a toggle's thumb size is changed all view buttons should be released" do
		toggle = HToggle.new_detached(4, 4)
		toggle.press(Point.new(0, 0))

		toggle.thumb_size = [2, 2]

		assert(toggle.all_released?)
	end

	test "when a toggle's thumb size is changed its leds should refresh" do
		toggle = @small_horizontal_toggle_4x1
		view_led_refreshed_listener = MockViewLedRefreshedListener.new(toggle)

		toggle.thumb_size = [2, 1]

		assert(
			view_led_refreshed_listener.has_been_notified_of?(
				[
					{ :source => :small_horizontal_toggle_4x1, :point => Point.new(0, 0), :on => true },
					{ :source => :small_horizontal_toggle_4x1, :point => Point.new(1, 0), :on => true },
					{ :source => :small_horizontal_toggle_4x1, :point => Point.new(2, 0), :on => false },
					{ :source => :small_horizontal_toggle_4x1, :point => Point.new(3, 0), :on => false },
				]
			)
		)
	end

	# inverted vs not inverted values
	test "a toggle that does not have inverted values should have correct led lit" do
		toggle = HToggle.new_detached(4, 1)
		toggle.value = 3
		toggle.values_are_inverted = false

		assert_equal(
			"  0 1 2 3      0 1 2 3\n" +
			"0 - - - -    0 - - - L\n",
			toggle.to_plot
		)
	end

	test "a toggle that has inverted values should have correct led lit" do
		toggle = HToggle.new_detached(4, 1)
		toggle.value = 3
		toggle.values_are_inverted = true

		assert_equal(
			"  0 1 2 3      0 1 2 3\n" +
			"0 - - - -    0 L - - -\n",
			toggle.to_plot
		)
	end

	test "when toggles value is set inverted all leds should automatically refresh" do
		toggle = @small_horizontal_toggle_4x1
		toggle.values_are_inverted = false
		toggle.value = 3
		view_led_refreshed_listener = MockViewLedRefreshedListener.new(toggle)

		toggle.values_are_inverted = true

		assert(
			view_led_refreshed_listener.has_been_notified_of?(
				[
					{ :source => :small_horizontal_toggle_4x1, :point => Point.new(0, 0), :on => true },
					{ :source => :small_horizontal_toggle_4x1, :point => Point.new(1, 0), :on => false },
					{ :source => :small_horizontal_toggle_4x1, :point => Point.new(2, 0), :on => false },
					{ :source => :small_horizontal_toggle_4x1, :point => Point.new(3, 0), :on => false },
				]
			)
		)
	end

	test "when toggles value is set inverted all pressed view buttons should be released" do
		toggle = HToggle.new_detached(4, 1)
		toggle.values_are_inverted = false
		toggle.press(Point.new(2, 0))

		toggle.values_are_inverted = true

		assert(toggle.all_released?)
	end

	test "when toggles value is set not inverted all leds should automatically refresh" do
		toggle = @small_horizontal_toggle_4x1
		toggle.values_are_inverted = true
		toggle.value = 3
		view_led_refreshed_listener = MockViewLedRefreshedListener.new(toggle)

		toggle.values_are_inverted = false

		assert(
			view_led_refreshed_listener.has_been_notified_of?(
				[
					{ :source => :small_horizontal_toggle_4x1, :point => Point.new(0, 0), :on => false },
					{ :source => :small_horizontal_toggle_4x1, :point => Point.new(1, 0), :on => false },
					{ :source => :small_horizontal_toggle_4x1, :point => Point.new(2, 0), :on => false },
					{ :source => :small_horizontal_toggle_4x1, :point => Point.new(3, 0), :on => true },
				]
			)
		)
	end

	test "when toggles value is set not inverted all pressed view buttons should be released" do
		toggle = HToggle.new_detached(4, 1)
		toggle.values_are_inverted = true
		toggle.press(Point.new(2, 0))

		toggle.values_are_inverted = false

		assert(toggle.all_released?)
	end

	# decoupled toggle behavior
	test "a decoupled toggle should not change value nor trigger main action when it is pressed nor released" do
		toggle = HToggle.new_decoupled(nil, nil, 4, 1)
		action_listener = MockActionListener.new(toggle)

		assert_equal(0, toggle.value)
		toggle.press(Point.new(0, 0))
		assert_equal(0, toggle.value)
		toggle.press(Point.new(1, 0))
		assert_equal(0, toggle.value)
		toggle.release(Point.new(0, 0))
		assert_equal(0, toggle.value)
		toggle.release(Point.new(1, 0))
		assert_equal(0, toggle.value)

		assert( action_listener.has_not_been_notified_of_anything? )
	end

	# coupled toggle behavior
	test "a coupled toggle should change value every time it is pressed" do
		toggle = @small_horizontal_toggle_4x1

		toggle.press(Point.new(3, 0))
		assert_equal(3, toggle.value)
		toggle.press(Point.new(1, 0))
		assert_equal(1, toggle.value)
		toggle.press(Point.new(2, 0))
		assert_equal(2, toggle.value)
	end

	test "a coupled toggle should trigger the main action every time it is pressed" do
		toggle = @small_horizontal_toggle_4x1
		action_listener = MockActionListener.new(toggle)

		toggle.press(Point.new(3, 0))

		assert( action_listener.has_been_notified_of?( [ [toggle, 3] ] ) )
		action_listener.reset_notifications

		toggle.press(Point.new(1, 0))

		assert( action_listener.has_been_notified_of?( [ [toggle, 1] ] ) )
		action_listener.reset_notifications

		toggle.press(Point.new(2, 0))

		assert( action_listener.has_been_notified_of?( [ [toggle, 2] ] ) )
		action_listener.reset_notifications
	end

	# nillable toggle behavior
	test "a nillable toggle should have its value set to nil if it is pressed on the button equivalent to the value it currently has" do
		toggle = HToggle.new_nillable(nil, nil, 4, 1)
		toggle.value = 3

		toggle.press(Point.new(3, 0))

		assert_equal(nil, toggle.value)
	end

	test "a nillable toggle should trigger the main action when its value is set to nil" do
		toggle = HToggle.new_nillable(nil, nil, 4, 1)
		toggle.value = 3
		action_listener = MockActionListener.new(toggle)

		toggle.press(Point.new(3, 0))

		assert( action_listener.has_been_notified_of?( [ [toggle, nil] ] ) )
	end

	test "when a nillable toggle with value nil is set not nillable it should get value 0" do
		toggle = HToggle.new_nillable(nil, nil, 4, 1)
		toggle.value = nil

		toggle.nillable = false

		assert_equal(0, toggle.value)
	end
end
