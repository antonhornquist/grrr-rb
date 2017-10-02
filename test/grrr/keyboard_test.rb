class TestKeyboard < Test::Unit::TestCase
	def setup
		save_globals
		disable_trace_and_flash
	end

	def teardown
		restore_globals
	end

	# Initialization

	test "a keyboard should by default be 7x2, coupled, have basenote 60 and indicate both black and white keys" do
		keyboard = Keyboard.new_detached
		assert_equal(7, keyboard.num_cols)
		assert_equal(2, keyboard.num_rows)
		assert(keyboard.is_coupled?)
		assert_equal(60, keyboard.basenote)
		assert_equal(:black_and_white, keyboard.indicate_keys)
	end

	test "it should be possible to create a decoupled keyboard" do
		assert_nothing_raised {
			Keyboard.new_decoupled(nil, nil, 7, 72)
		}
	end

	# Basenote and keyrange

=begin
	TODO
	test "it should only be possible to create a keyboard with a basenote that is a white key on the keyboard" do
		assert_nothing_raised {
			Keyboard.new_detached(7, 72)
		}
		assert_raise(RuntimeError) {
			Keyboard.new_detached(7, 73)
		}
	end
=end

	test "it should be possible to change basenote of a keyboard" do
		keyboard = Keyboard.new_detached(7, 60)
		
		keyboard.basenote = 62

		assert_equal(62, keyboard.basenote)
	end

=begin
	TODO
	test "it should not be possible to change basenote to a note that is not a white key on the keyboard" do
		keyboard = Keyboard.new_detached(7, 60)
		
		assert_raise(RuntimeError) {
			keyboard.basenote = 61
		}
	end
=end

	test "when basenote property is changed pressed buttons on keyboard view should be released" do
		keyboard = Keyboard.new_detached(7, 60)
		keyboard.press(Point.new(0, 1))
		keyboard.press(Point.new(2, 0))
		keyboard.press(Point.new(4, 1))

		keyboard.basenote = 62
		
		assert(keyboard.all_released?)
	end

=begin
	TODO
	test "when basenote is changed the keyboard should automatically refresh" do
		keyboard = Keyboard.new_detached(7, 60)
		keyboard.id = :keyboard
		view_led_refreshed_listener = MockViewLedRefreshedListener.new(keyboard)

		keyboard.basenote = 62
		
		assert(
			view_led_refreshed_listener.has_been_notified_of?(
				[
					{ :source => :keyboard, :point => Point.new(0, 0), :on => true },
					{ :source => :keyboard, :point => Point.new(1, 0), :on => true },
					{ :source => :keyboard, :point => Point.new(2, 0), :on => false },
					{ :source => :keyboard, :point => Point.new(3, 0), :on => true },
					{ :source => :keyboard, :point => Point.new(4, 0), :on => true },
					{ :source => :keyboard, :point => Point.new(5, 0), :on => true },
					{ :source => :keyboard, :point => Point.new(6, 0), :on => false },
					{ :source => :keyboard, :point => Point.new(0, 1), :on => true },
					{ :source => :keyboard, :point => Point.new(1, 1), :on => true },
					{ :source => :keyboard, :point => Point.new(2, 1), :on => true },
					{ :source => :keyboard, :point => Point.new(3, 1), :on => true },
					{ :source => :keyboard, :point => Point.new(4, 1), :on => true },
					{ :source => :keyboard, :point => Point.new(5, 1), :on => true },
					{ :source => :keyboard, :point => Point.new(6, 1), :on => true },
				]
			)
		)
	end

	test "it should be possible to retrieve the keyrange of a keyboard" do
		keyboard = Keyboard.new_detached(3, 62)
		assert_equal(
			(61..65),
			keyboard.keyrange
		)
	end

	test "it should be possible to retrieve the number of notes in the keyrange of a keyboard" do
		keyboard = Keyboard.new_detached(4, 60)

		assert_equal(
			6,
			keyboard.num_notes
		)
	end

	test "the value of a keyboard should be an array of boolean values corresponding to how notes are displayed" do
		keyboard = Keyboard.new_detached(7, 60)

		keyboard.press(Point.new(2, 1))
		keyboard.press(Point.new(3, 0))

		assert(
			[false, false, false, false, true, true, false, false, false, false, false, false, false],
			keyboard.value
		)
	end

	test "when a note is displayed as pressed on a keyboard its corresponding led should be inverted from its normal led state" do
		keyboard = Keyboard.new_detached(7, 60)

		keyboard.display_note_as_pressed(64)

		assert_equal(
			true,
			keyboard.is_unlit_at?(Point.new(2, 1))
		)
	end

	# Note press / release events and state

	test "when a button on the keyboard view that corresponds to a note is pressed the state should be reflected" do
		keyboard = Keyboard.new_detached(7, 60)

		keyboard.press(Point.new(2, 1))

		assert(keyboard.note_is_pressed?(64))
	end

	test "when a button on the keyboard view that corresponds to a note that currently is pressed is released the state should be reflected" do
		keyboard = Keyboard.new_detached(7, 60)
		keyboard.press(Point.new(2, 1))

		keyboard.release(Point.new(2, 1))

		assert(keyboard.note_is_released?(64))
	end

	test "it should be possible to get notified of notes being pressed on view by adding an action to a keyboard" do
		keyboard = Keyboard.new_detached(7, 60)
		listener = MockNotePressedListener.new(keyboard)

		keyboard.press(Point.new(2, 1))
		keyboard.press(Point.new(4, 1))
		keyboard.press(Point.new(1, 0))
		keyboard.release(Point.new(4, 1))
		keyboard.release(Point.new(1, 0))
		keyboard.release(Point.new(2, 1))

		assert(
			listener.has_been_notified_of?( [[keyboard, 64], [keyboard, 67], [keyboard, 61]] )
		)
	end

	test "it should be possible to get notified of notes getting released on view by adding an action to a keyboard" do
		keyboard = Keyboard.new_detached(7, 60)
		listener = MockNoteReleasedListener.new(keyboard)

		keyboard.press(Point.new(2, 1))
		keyboard.press(Point.new(4, 1))
		keyboard.press(Point.new(1, 0))
		keyboard.release(Point.new(4, 1))
		keyboard.release(Point.new(1, 0))
		keyboard.release(Point.new(2, 1))

		assert(
			listener.has_been_notified_of?( [[keyboard, 67], [keyboard, 61], [keyboard, 64]] )
		)
	end

	test "it should be possible to determine in what order currently pressed notes on a keyboard have been pressed on the view" do
		keyboard = Keyboard.new_detached(7, 60)

		keyboard.press(Point.new(2, 1))
		keyboard.press(Point.new(4, 1))
		keyboard.press(Point.new(1, 0))
		keyboard.release(Point.new(4, 1))
		keyboard.press(Point.new(4, 1))

		assert_equal([64, 61, 67], keyboard.notes_pressed)
	end

	# Note display

	test "it should be possible to display notes as pressed on a decoupled keyboard" do
		keyboard = Keyboard.new_decoupled(nil, nil, 7, 60)

		keyboard.display_note_as_pressed(61)

		assert(
			keyboard.note_is_displayed_as_pressed?(61)
		)
	end

	test "it should be possible to display notes as released on a decoupled keyboard" do
		keyboard = Keyboard.new_decoupled(nil, nil, 7, 60)
		keyboard.display_note_as_pressed(61)

		keyboard.display_note_as_released(61)

		assert(
			keyboard.note_is_displayed_as_released?(61)
		)
	end

	# Coupling and decoupling

	test "a coupled keyboard should update note display state" do
		keyboard = Keyboard.new_detached(7, 60)

		keyboard.press(Point.new(2, 1))

		assert(keyboard.note_is_displayed_as_pressed?(64))

		keyboard.release(Point.new(2, 1))

		assert(keyboard.note_is_displayed_as_released?(64))
	end

	test "a decoupled keyboard should not update display state" do
		keyboard = Keyboard.new_decoupled(nil, nil, 7, 60)

		keyboard.press(Point.new(2, 1))

		assert(keyboard.note_is_displayed_as_released?(64))

		keyboard.display_note_as_pressed(64)
		keyboard.release(Point.new(2, 1))

		assert(keyboard.note_is_displayed_as_pressed?(64))
	end

	test "when a keyboard is set decoupled and vice versa all pressed buttons on view should be released" do
		keyboard = Keyboard.new_detached(7, 60)
		keyboard.press(Point.new(0, 1))

		keyboard.coupled = false
		
		assert(
			keyboard.all_released?
		)

		keyboard.press(Point.new(0, 1))

		keyboard.coupled = true
		
		assert(
			keyboard.all_released?
		)
	end

	# Indicate keys

	test "when indicate keys property is black and white leds of all keyboard keys should be lit" do
		keyboard = Keyboard.new_detached(7, 60)

		keyboard.indicate_keys = :black_and_white

		assert_equal(
			"  0 1 2 3 4 5 6      0 1 2 3 4 5 6\n" +
			"0 - - - - - - -    0 - L L - L L L\n" +
			"1 - - - - - - -    1 L L L L L L L\n",
			keyboard.to_plot
		)
	end

	test "when indicate keys property is black leds of all black keyboard keys should be lit" do
		keyboard = Keyboard.new_detached(7, 60)

		keyboard.indicate_keys = :black

		assert_equal(
			"  0 1 2 3 4 5 6      0 1 2 3 4 5 6\n" +
			"0 - - - - - - -    0 - L L - L L L\n" +
			"1 - - - - - - -    1 - - - - - - -\n",
			keyboard.to_plot
		)
	end

	test "when indicate keys property is white leds of all white keyboard keys should be lit" do
		keyboard = Keyboard.new_detached(7, 60)

		keyboard.indicate_keys = :white

		assert_equal(
			"  0 1 2 3 4 5 6      0 1 2 3 4 5 6\n" +
			"0 - - - - - - -    0 - - - - - - -\n" +
			"1 - - - - - - -    1 L L L L L L L\n",
			keyboard.to_plot
		)
	end

	test "when indicate keys property is none no leds should be lit" do
		keyboard = Keyboard.new_detached(7, 60)

		keyboard.indicate_keys = :none

		assert_equal(
			"  0 1 2 3 4 5 6      0 1 2 3 4 5 6\n" +
			"0 - - - - - - -    0 - - - - - - -\n" +
			"1 - - - - - - -    1 - - - - - - -\n",
			keyboard.to_plot
		)
	end

	test "when indicate keys property is changed the keyboard should automatically refresh" do
		keyboard = Keyboard.new_detached(7, 60)
		keyboard.id = :keyboard
		view_led_refreshed_listener = MockViewLedRefreshedListener.new(keyboard)

		keyboard.indicate_keys = :none
		
		assert(
			view_led_refreshed_listener.has_been_notified_of?(
				[
					{ :source => :keyboard, :point => Point.new(0, 0), :on => false },
					{ :source => :keyboard, :point => Point.new(1, 0), :on => false },
					{ :source => :keyboard, :point => Point.new(2, 0), :on => false },
					{ :source => :keyboard, :point => Point.new(3, 0), :on => false },
					{ :source => :keyboard, :point => Point.new(4, 0), :on => false },
					{ :source => :keyboard, :point => Point.new(5, 0), :on => false },
					{ :source => :keyboard, :point => Point.new(6, 0), :on => false },
					{ :source => :keyboard, :point => Point.new(0, 1), :on => false },
					{ :source => :keyboard, :point => Point.new(1, 1), :on => false },
					{ :source => :keyboard, :point => Point.new(2, 1), :on => false },
					{ :source => :keyboard, :point => Point.new(3, 1), :on => false },
					{ :source => :keyboard, :point => Point.new(4, 1), :on => false },
					{ :source => :keyboard, :point => Point.new(5, 1), :on => false },
					{ :source => :keyboard, :point => Point.new(6, 1), :on => false },
				]
			)
		)
	end
=end
end
