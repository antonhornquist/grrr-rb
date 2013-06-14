class TestView < Test::Unit::TestCase
	def setup
		save_globals
		disable_trace_and_flash
		@a_detached_4x4_view = View.new(nil, nil, 4, 4)
		@a_detached_4x4_view.id = :a_detached_4x4_view
		@a_detached_2x3_view = View.new(nil, nil, 2, 3)
		@a_detached_2x3_view.id = :a_detached_2x3_view
		@a_detached_2x2_view = View.new(nil, nil, 2, 2)
		@a_detached_2x2_view.id = :a_detached_2x2_view
		@a_disabled_4x4_view = View.new(nil, nil, 4, 4, false)
		@a_disabled_4x4_view.id = :a_disabled_4x4_view
		@a_disabled_2x2_view = View.new(nil, nil, 2, 2, false)
		@a_disabled_2x2_view.id = :a_disabled_2x2_view
	end

	def teardown
		restore_globals
	end

	# initialization
	test "a view should by default be enabled" do
		view = View.new(nil, nil)
		assert(view.is_enabled?)
	end

	test "a view created with new disabled should be disabled" do
		view = View.new_disabled(nil, nil)
		assert(view.is_disabled?)
	end

	test "a view created with new detached should be detached" do
		view = View.new_detached(4, 4)
		assert(view.is_detached?)
	end

	test "if only num cols is specified on view creation num rows should be set to specified num cols value" do
		view = View.new(nil, nil, 1)
		detached_view = View.new_detached(2)
		disabled_view = View.new_disabled(nil, nil, 3)
		assert_equal(1, view.num_cols)
		assert_equal(1, view.num_rows)
		assert_equal(2, detached_view.num_cols)
		assert_equal(2, detached_view.num_rows)
		assert_equal(3, disabled_view.num_cols)
		assert_equal(3, disabled_view.num_rows)
	end

	test "it should not be possible to create a view smaller than 1x1" do
		assert_raise(RuntimeError) { View.new_detached(0, 1) }
		assert_raise(RuntimeError) { View.new_detached(1, 0) }
		assert_raise(RuntimeError) { View.new_detached(0, 0) }
	end

	# id
	test "it should be possible to assign an id to a view" do
		view = @a_detached_4x4_view
		view.id = :test
		assert_equal(:test, view.id)
	end

	# enable / disable
	test "it should be possible to disable enabled views" do
		view = @a_detached_4x4_view
		view.disable
		assert(view.is_disabled?)
	end

	test "it should be possible to enable disabled views" do
		view = @a_disabled_4x4_view
		view.enable
		assert(view.is_enabled?)
	end

	test "it should be possible to get notified of when a view is enabled by adding an action to a view" do
		view = @a_detached_4x4_view
		listener = MockViewWasDisabledListener.new(view)

		view.disable

		assert( listener.has_been_notified_of?( [ [view] ] ) )
	end

	test "it should be possible to get notified of when a view is disabled by adding an action to a view" do
		view = @a_disabled_4x4_view
		listener = MockViewWasEnabledListener.new(view)

		view.enable

		assert( listener.has_been_notified_of?( [ [view] ] ) )
	end

	# bounds
	test "it should be possible to retrieve the bounds of and number of buttons on a view" do
		view = @a_detached_2x3_view
		assert_equal(2, view.num_cols)
		assert_equal(3, view.num_rows)
		assert_equal(6, view.num_view_buttons)
	end

	test "it should be possible to retrieve points of a view" do
		assert_equal(
			[
				Point.new(0, 0), Point.new(1, 0),
				Point.new(0, 1), Point.new(1, 1),
				Point.new(0, 2), Point.new(1, 2)
			],
			@a_detached_2x3_view.to_points
		)
	end

	test "it should be possible to retrieve points of a view starting from an origin" do
		assert_equal(
			[
				Point.new(10, 20), Point.new(11, 20),
				Point.new(10, 21), Point.new(11, 21),
				Point.new(10, 22), Point.new(11, 22)
			],
			@a_detached_2x3_view.to_points_from(Point.new(10, 20))
		)
	end

	test "it should be possible to convert bounds to points" do
		assert_equal(
			[
				Point.new(5, 2), Point.new(6, 2), Point.new(7, 2), Point.new(8, 2), Point.new(9, 2),
				Point.new(5, 3), Point.new(6, 3), Point.new(7, 3), Point.new(8, 3), Point.new(9, 3),
				Point.new(5, 4), Point.new(6, 4), Point.new(7, 4), Point.new(8, 4), Point.new(9, 4),
			],
			View.bounds_to_points(Point.new(5, 2), 5, 3)
		)
	end

	test "it should be possible to calculate the intersect of two point arrays" do
		assert_equal(
			[
				Point.new(2, 1),
				Point.new(2, 2),
				Point.new(2, 3)
			],
			View.points_sect(
				[
					Point.new(0, 0), Point.new(1, 0), Point.new(2, 0),
					Point.new(0, 1), Point.new(1, 1), Point.new(2, 1),
					Point.new(0, 2), Point.new(1, 2), Point.new(2, 2),
					Point.new(0, 3), Point.new(1, 3), Point.new(2, 3),
				],
				[
					Point.new(2, 1), Point.new(3, 1), Point.new(4, 1),
					Point.new(2, 2), Point.new(3, 2), Point.new(4, 2),
					Point.new(2, 3), Point.new(3, 3), Point.new(4, 3),
					Point.new(2, 4), Point.new(3, 4), Point.new(4, 4),
				]
			)
		)
	end

	test "it should be possible to determine if a specified bounds contains a specified point" do
		assert(
			View.bounds_contain_point?(Point.new(2, 3), 3, 2, Point.new(3, 4))
		)
		assert_equal(
			false,
			View.bounds_contain_point?(Point.new(2, 3), 3, 2, Point.new(1, 1))
		)
	end

	test "it should be possible to retrieve the left top, right top, left bottom and right bottom points of a view" do
		assert_equal(
			Point.new(0, 0),
			@a_detached_2x3_view.left_top_point
		)
		assert_equal(
			Point.new(1, 0),
			@a_detached_2x3_view.right_top_point
		)
		assert_equal(
			Point.new(0, 2),
			@a_detached_2x3_view.left_bottom_point
		)
		assert_equal(
			Point.new(1, 2),
			@a_detached_2x3_view.right_bottom_point
		)
	end

	# validations
	test "it should be possible to determine if a view contains a specified point" do
		view = @a_detached_2x3_view

		assert(view.contains_point?(Point.new(0, 0)))
		assert(view.contains_point?(Point.new(1, 2)))

		assert_equal( false, view.contains_point?(Point.new(2, 2)) )
		assert_equal( false, view.contains_point?(Point.new(1, 3)) )
		assert_equal( false, view.contains_point?(Point.new(2, 3)) )

		assert_equal( false, view.contains_point?(Point.new(-1, 0)) )
		assert_equal( false, view.contains_point?(Point.new(0, -1)) )
		assert_equal( false, view.contains_point?(Point.new(-1, -1)) )

		assert_nothing_raised { view.validate_contains_point(Point.new(0, 0)) }
		assert_nothing_raised { view.validate_contains_point(Point.new(1, 2)) }

		assert_raise(RuntimeError) { view.validate_contains_point(Point.new(2, 2)) }
		assert_raise(RuntimeError) { view.validate_contains_point(Point.new(1, 3)) }
		assert_raise(RuntimeError) { view.validate_contains_point(Point.new(2, 3)) }

		assert_raise(RuntimeError) { view.validate_contains_point(Point.new(-1, 0)) }
		assert_raise(RuntimeError) { view.validate_contains_point(Point.new(0, -1)) }
		assert_raise(RuntimeError) { view.validate_contains_point(Point.new(-1, -1)) }
	end

	test "it should be possible to determine if a view contains a specified bounds" do
		view = @a_detached_2x3_view

		assert(view.contains_bounds?(Point.new(0, 0), 2, 3))
		assert(view.contains_bounds?(Point.new(0, 0), 2, 1))
		assert(view.contains_bounds?(Point.new(1, 2), 1, 1))

		assert_equal( false, view.contains_bounds?(Point.new(0, 0), 3, 3) )
		assert_equal( false, view.contains_bounds?(Point.new(1, 2), 1, 2) )
		assert_equal( false, view.contains_bounds?(Point.new(1, 2), 2, 1) )

		assert_equal( false, view.contains_bounds?(Point.new(-1, 0), 1, 1) )
		assert_equal( false, view.contains_bounds?(Point.new(0, -1), 1, 1) )
		assert_equal( false, view.contains_bounds?(Point.new(-1, -1), 1, 1) )

		assert_nothing_raised { view.validate_contains_bounds(Point.new(0, 0), 2, 3) }
		assert_nothing_raised { view.validate_contains_bounds(Point.new(0, 0), 2, 1) }
		assert_nothing_raised { view.validate_contains_bounds(Point.new(1, 2), 1, 1) }

		assert_raise(RuntimeError) { view.validate_contains_bounds(Point.new(0, 0), 3, 3) }
		assert_raise(RuntimeError) { view.validate_contains_bounds(Point.new(1, 2), 1, 2) }
		assert_raise(RuntimeError) { view.validate_contains_bounds(Point.new(1, 2), 2, 1) }

		assert_raise(RuntimeError) { view.validate_contains_bounds(Point.new(-1, 0), 1, 1) }
		assert_raise(RuntimeError) { view.validate_contains_bounds(Point.new(0, -1), 1, 1) }
		assert_raise(RuntimeError) { view.validate_contains_bounds(Point.new(-1, -1), 1, 1) }
	end

	# action and value
	test "it should be possible to get notified of view events by adding actions to a view" do
		view = @a_detached_2x2_view
		action_listener1 = MockActionListener.new(view)
		action_listener2 = MockActionListener.new(view)

		view.action.call("hey, something happened")

		assert( action_listener1.has_been_notified_of?( [ ["hey, something happened"] ] ) )
		assert( action_listener2.has_been_notified_of?( [ ["hey, something happened"] ] ) )
	end

	test "it should be possible to remove added actions from a view" do
		view = @a_detached_2x2_view
		action_listener1 = MockActionListener.new(view)
		action_listener2 = MockActionListener.new(view)

		action_listener1.remove_listener
		action_listener2.remove_listener

		assert_equal( nil, view.action )
	end

	test "an action should no longer receive notifications once it has been removed from a view" do
		view = @a_detached_2x2_view
		action_listener1 = MockActionListener.new(view)
		action_listener2 = MockActionListener.new(view)

		action_listener1.remove_listener

		view.action.call("hey, something happened")

		assert( action_listener1.has_not_been_notified_of_anything? )
		assert( action_listener2.has_been_notified_of?( [ ["hey, something happened"] ] ) )
	end

	test "it should be possible to set a views value" do
		view = @a_detached_2x2_view
		view.value = :xyz
		assert_equal(:xyz, view.value)
	end

	test "when a views value is set to a new value the view should be refreshed" do
		view = @a_detached_2x2_view
		view.value = :abc
		view_led_refreshed_listener = MockViewLedRefreshedListener.new(view)

		view.value = :def

		assert(
			view_led_refreshed_listener.has_been_notified_of?(
				[
					{ :source => :a_detached_2x2_view, :point => Point.new(0, 0), :on => false },
					{ :source => :a_detached_2x2_view, :point => Point.new(1, 0), :on => false },
					{ :source => :a_detached_2x2_view, :point => Point.new(0, 1), :on => false },
					{ :source => :a_detached_2x2_view, :point => Point.new(1, 1), :on => false }
				]
			)
		)
	end

	test "when a views value is set but not changed the view should not be refreshed" do
		view = @a_detached_2x2_view
		view.value = :abc
		view_led_refreshed_listener = MockViewLedRefreshedListener.new(view)

		view.value = :abc

		assert(view_led_refreshed_listener.has_not_been_notified_of_anything?)
	end

	test "when a views value is set to a new value using value action the view should be refreshed and action should be triggered" do
		view = @a_detached_2x2_view
		view_led_refreshed_listener = MockViewLedRefreshedListener.new(view)
		action_listener = MockActionListener.new(view)

		view.value_action = :xyz

		assert(
			view_led_refreshed_listener.has_been_notified_of?(
				[
					{ :source => :a_detached_2x2_view, :point => Point.new(0, 0), :on => false },
					{ :source => :a_detached_2x2_view, :point => Point.new(1, 0), :on => false },
					{ :source => :a_detached_2x2_view, :point => Point.new(0, 1), :on => false },
					{ :source => :a_detached_2x2_view, :point => Point.new(1, 1), :on => false }
				]
			)
		)
		assert( action_listener.has_been_notified_of?( [ [view, :xyz] ] ) )
	end

	test "when a views value is set but not changed using value action the view should not be refreshed and no action should be triggered" do
		view = @a_detached_2x2_view
		view.value = :abc
		view_led_refreshed_listener = MockViewLedRefreshedListener.new(view)
		action_listener = MockActionListener.new(view)

		view.value_action = :abc

		assert(view_led_refreshed_listener.has_not_been_notified_of_anything?)
		assert(action_listener.has_not_been_notified_of_anything?)
	end

	# button events and state
	test "it should be possible to send a button event to a view and get a response of how the event was handled" do
		view = @a_detached_4x4_view

		response = view.press(Point.new(0, 0))

		assert_equal(
			[
				{:view => view, :point => Point.new(0, 0)}
			],
			response
		)
	end

	test "button state should be saved for each view and should be updated by incoming button events" do
		view = @a_detached_4x4_view

		view.press(Point.new(0, 0))

		assert(view.is_pressed_at?(Point.new(0, 0)))

		view.release(Point.new(0, 0))

		assert(view.is_released_at?(Point.new(0, 0)))
	end

	test "all buttons of a view should be released on creation" do
		assert(@a_detached_4x4_view.all_released?)
	end

	test "when the button state of a view is updated by incoming button events the views view button state changed actions should be triggered with notification of the update" do
		view = @a_detached_4x4_view
		view_button_state_changed_listener = MockViewButtonStateChangedListener.new(view)
		view.press(Point.new(1, 1))
		view.release(Point.new(1, 1))

		assert(
			view_button_state_changed_listener.has_been_notified_of?(
				[
					{ :point => Point.new(1, 1), :pressed => true },
					{ :point => Point.new(1, 1), :pressed => false }
				]
			)
		)
	end

	test "a disabled view should not respond to button events" do
		view = @a_disabled_4x4_view
		response = view.press(Point.new(0, 0))
		assert_equal(nil, response)
	end

	test "a disabled view should not update button state according to incoming button events" do
		view = @a_disabled_4x4_view
		view.press(Point.new(0, 0))
		assert(view.is_released_at?(Point.new(0, 0)))
	end

	test "subsequent button events of the same type and on the same button should be ignored" do
		view = @a_detached_4x4_view
		view_button_state_changed_listener = MockViewButtonStateChangedListener.new(view)

		response = view.press(Point.new(1, 1))

		assert_equal(
			[
				{:view => view, :point => Point.new(1, 1)}
			],
			response
		)
		assert( view.is_pressed_at?(Point.new(1, 1)) )
		assert(
			view_button_state_changed_listener.has_been_notified_of?(
				[
					{ :point => Point.new(1, 1), :pressed => true }
				]
			)
		)

		response = view.press(Point.new(1, 1))

		assert_equal(
			[],
			response
		)
		assert( view.is_pressed_at?(Point.new(1, 1)) )
		assert(
			view_button_state_changed_listener.has_been_notified_of?(
				[
					{ :point => Point.new(1, 1), :pressed => true }
				]
			)
		)

		response = view.release(Point.new(1, 1))

		assert_equal(
			[
				{:view => view, :point => Point.new(1, 1)}
			],
			response
		)
		assert( view.is_released_at?(Point.new(1, 1)) )
		assert(
			view_button_state_changed_listener.has_been_notified_of?(
				[
					{ :point => Point.new(1, 1), :pressed => true },
					{ :point => Point.new(1, 1), :pressed => false }
				]
			)
		)

		response = view.release(Point.new(1, 1))

		assert_equal(
			[],
			response
		)
		assert( view.is_released_at?(Point.new(1, 1)) )
		assert(
			view_button_state_changed_listener.has_been_notified_of?(
				[
					{ :point => Point.new(1, 1), :pressed => true },
					{ :point => Point.new(1, 1), :pressed => false }
				]
			)
		)
	end

	test "it should be possible to determine how many buttons on a view are pressed" do
		view = @a_detached_4x4_view

		view.press(Point.new(0, 0))
		view.press(Point.new(1, 1))
		view.press(Point.new(2, 2))

		assert_equal(3, view.num_pressed)
	end

	test "it should be possible to determine how many buttons within a specified part of a view are pressed" do
		view = @a_detached_4x4_view

		view.press(Point.new(0, 0))
		view.press(Point.new(1, 1))
		view.press(Point.new(2, 2))

		assert_equal(2, view.num_pressed_within_bounds(Point.new(1, 1), 2, 2))
	end

	test "it should be possible to determine how many buttons on a view are released" do
		view = @a_detached_4x4_view

		view.press(Point.new(0, 0))
		view.press(Point.new(1, 1))
		view.press(Point.new(2, 2))

		assert_equal(13, view.num_released)
	end

	test "it should be possible to determine how many buttons within a specified part of a view are released" do
		view = @a_detached_4x4_view

		view.press(Point.new(0, 0))
		view.press(Point.new(1, 1))
		view.press(Point.new(2, 2))

		assert_equal(2, view.num_released_within_bounds(Point.new(1, 1), 2, 2))
	end

	test "it should be possible to determine if any button on a view is pressed" do
		view = @a_detached_2x2_view

		assert_equal(false, view.any_pressed?)

		view.press(Point.new(0, 0))

		assert(view.any_pressed?)
	end

	test "it should be possible to determine if any button within a specified part of a view is pressed" do
		view = @a_detached_4x4_view

		view.press(Point.new(0, 0))

		assert_equal(false, view.any_pressed_within_bounds?(Point.new(1, 1), 2, 2))

		view.press(Point.new(1, 1))

		assert(view.any_pressed_within_bounds?(Point.new(1, 1), 2, 2))
	end

	test "it should be possible to determine if all buttons on a view are pressed" do
		view = @a_detached_2x2_view

		assert_equal(false, view.all_pressed?)

		view.to_points.each { |point| view.press(point) }

		assert(view.all_pressed?)
	end

	test "it should be possible to determine if all buttons within a specified part of a view are pressed" do
		view = @a_detached_4x4_view

		view.press(Point.new(0, 0))

		assert_equal(false, view.all_pressed_within_bounds?(Point.new(1, 1), 2, 2))

		view.to_points.each { |point| view.press(point) }

		assert(view.all_pressed_within_bounds?(Point.new(1, 1), 2, 2))
	end

	test "it should be possible to determine if any button on a view is released" do
		view = @a_detached_2x2_view

		assert(view.any_released?)

		view.press(Point.new(0, 0))

		assert(view.any_released?)

		view.press(Point.new(0, 1))
		view.press(Point.new(1, 0))
		view.press(Point.new(1, 1))

		assert_equal(false, view.any_released?)
	end

	test "it should be possible to determine if any button within a specified part of a view is released" do
		view = @a_detached_4x4_view

		assert(view.any_released_within_bounds?(Point.new(1, 1), 2, 2))

		view.press(Point.new(1, 1))

		assert(view.any_released_within_bounds?(Point.new(1, 1), 2, 2))

		view.press(Point.new(1, 2))
		view.press(Point.new(2, 1))
		view.press(Point.new(2, 2))

		assert_equal(false, view.any_released_within_bounds?(Point.new(1, 1), 2, 2))
	end

	test "it should be possible to determine if all buttons on a view are released" do
		view = @a_detached_2x2_view

		assert(view.all_released?)

		view.press(Point.new(0, 0))

		assert_equal(false, view.all_released?)

		view.press(Point.new(0, 1))
		view.press(Point.new(1, 0))
		view.press(Point.new(1, 1))

		assert_equal(false, view.all_released?)
	end

	test "it should be possible to determine if all buttons within a specified part of a view are released" do
		view = @a_detached_4x4_view

		assert(view.all_released_within_bounds?(Point.new(1, 1), 2, 2))

		view.press(Point.new(1, 1))

		assert_equal(false, view.all_released_within_bounds?(Point.new(1, 1), 2, 2))

		view.press(Point.new(1, 2))
		view.press(Point.new(2, 1))
		view.press(Point.new(2, 2))

		assert_equal(false, view.all_released_within_bounds?(Point.new(1, 1), 2, 2))
	end

	test "it should be possible to determine which of the currently pressed buttons on a view was pressed first" do
		view = @a_detached_4x4_view

		assert_equal(nil, view.first_pressed)

		view.press(Point.new(0, 0))

		assert_equal(Point.new(0, 0), view.first_pressed)

		view.press(Point.new(1, 1))
		view.press(Point.new(2, 2))
		view.release(Point.new(0, 0))

		assert_equal(Point.new(1, 1), view.first_pressed)
	end

	test "it should be possible to determine which of the currently pressed buttons on a view was pressed last" do
		view = @a_detached_4x4_view

		assert_equal(nil, view.last_pressed)

		view.press(Point.new(0, 0))

		assert_equal(Point.new(0, 0), view.last_pressed)

		view.press(Point.new(1, 1))
		view.press(Point.new(2, 2))
		view.press(Point.new(3, 3))
		view.release(Point.new(3, 3))

		assert_equal(Point.new(2, 2), view.last_pressed)
	end

	test "it should be possible to determine in what order currently pressed buttons have been pressed on a view" do
		view = @a_detached_4x4_view

		view.press(Point.new(3, 3))
		view.press(Point.new(0, 0))
		view.press(Point.new(1, 1))
		view.press(Point.new(2, 2))
		view.release(Point.new(1, 1))

		assert_equal(
			[
				Point.new(3, 3),
				Point.new(0, 0),
				Point.new(2, 2)
			],
			view.points_pressed
		)
	end

	test "it should be possible to determine in what order currently pressed buttons within a specified part of a view have been pressed" do
		view = @a_detached_4x4_view

		view.press(Point.new(3, 3))
		view.press(Point.new(0, 0))
		view.press(Point.new(1, 1))
		view.press(Point.new(2, 2))
		view.release(Point.new(1, 1))

		assert_equal(
			[
				Point.new(3, 3),
				Point.new(2, 2)
			],
			view.points_pressed_within_bounds(Point.new(2, 2), 2, 2)
		)
	end

	test "it should be possible to determine which left right top and bottommost buttons are pressed on a view" do
		view = @a_detached_4x4_view

		assert_equal([], view.leftmost_pressed)
		assert_equal(nil, view.leftmost_col_pressed)
		assert_equal([], view.rightmost_pressed)
		assert_equal(nil, view.rightmost_col_pressed)
		assert_equal([], view.topmost_pressed)
		assert_equal(nil, view.topmost_row_pressed)
		assert_equal([], view.bottommost_pressed)
		assert_equal(nil, view.bottommost_row_pressed)

		[ Point.new(1,1),
			Point.new(3,1),
			Point.new(3,3),
			Point.new(1,3) ].each { |point| view.press(point) }

		assert_equal(
			[ Point.new(1,1), Point.new(1,3) ],
			view.leftmost_pressed
		)
		assert_equal(1, view.leftmost_col_pressed)

		assert_equal(
			[ Point.new(3,1), Point.new(3,3) ],
			view.rightmost_pressed
		)
		assert_equal(3, view.rightmost_col_pressed)

		assert_equal(
			[ Point.new(1,1), Point.new(3,1) ],
			view.topmost_pressed
		)
		assert_equal(1, view.topmost_row_pressed)

		assert_equal(
			[ Point.new(3,3), Point.new(1,3) ],
			view.bottommost_pressed
		)
		assert_equal(3, view.bottommost_row_pressed)
	end

	test "when a view is disabled all pressed buttons of view should be released" do
		view = @a_detached_4x4_view
		view.to_points.each { |point| view.press(point) }
		view.disable
		assert(view.all_released?)
	end

	# out of bounds errors
	test "an out of bounds button state check should throw an error" do
		view = @a_detached_4x4_view
		assert_raise(RuntimeError) { view.is_pressed_at?(Point.new(4, 4)) }
	end

	test "an out of bounds button event should throw an error" do
		view = @a_detached_2x3_view

		assert_raise(RuntimeError) { view.press(Point.new(-1, 0)) }
		assert_raise(RuntimeError) { view.press(Point.new(0, -1)) }
		assert_raise(RuntimeError) { view.press(Point.new(2, 1)) }
		assert_raise(RuntimeError) { view.press(Point.new(3, 1)) }
		assert_raise(RuntimeError) { view.press(Point.new(1, 3)) }
		assert_raise(RuntimeError) { view.press(Point.new(1, 4)) }
	end

	test "an out of bounds led state check should throw an error" do
		view = @a_detached_4x4_view
		assert_raise(RuntimeError) { view.is_lit_at?(Point.new(4, 4)) }
	end

	test "an out of bounds refresh point should throw an error" do
		view = @a_detached_4x4_view
		assert_raise(RuntimeError) { view.refresh_point(Point.new(4, 4)) }
	end

	# led state
	test "it should be possible to check whether a led of a view is lit" do
		view = MockOddColsLitView.new_detached(4, 4)

		assert(view.is_lit_at?(Point.new(1, 0)))
	end

	test "it should be possible to check whether any led of a view is lit" do
		view = MockOddColsLitView.new_detached(4, 4)

		assert(view.any_lit?)
	end

	test "it should be possible to check whether all leds of a view are lit" do
		view = MockLitView.new_detached(4, 4)

		assert(view.all_lit?)
	end

	test "it should be possible to check whether a led of a view is unlit" do
		view = MockOddColsLitView.new_detached(4, 4)

		assert(view.is_unlit_at?(Point.new(0, 0)))
	end

	test "it should be possible to check whether any led of a view is unlit" do
		view = MockOddColsLitView.new_detached(4, 4)

		assert(view.any_unlit?)
	end

	test "it should be possible to check whether all leds of a view are unlit" do
		view = MockUnlitView.new_detached(4, 4)

		assert(view.all_unlit?)
	end

	# led events and refresh
	test "when a point of an enabled view is refreshed the views view led refreshed actions should get notified of the refreshed led and its state" do
		view = @a_detached_4x4_view
		view_led_refreshed_listener = MockViewLedRefreshedListener.new(view)

		view.refresh_point(Point.new(1, 1))

		assert(
			view_led_refreshed_listener.has_been_notified_of?(
				[
					{ :source => :a_detached_4x4_view, :point => Point.new(1, 1), :on => false }
				]
			)
		)
	end

	test "when bounds of an enabled view is refreshed the views view led refreshed actions should get notified of refreshed leds and their state" do
		view = @a_detached_4x4_view
		view_led_refreshed_listener = MockViewLedRefreshedListener.new(view)

		view.refresh_bounds(Point.new(2, 2), 2, 2)

		assert(
			view_led_refreshed_listener.has_been_notified_of?(
				[
					{ :source => :a_detached_4x4_view, :point => Point.new(2, 2), :on => false },
					{ :source => :a_detached_4x4_view, :point => Point.new(3, 2), :on => false },
					{ :source => :a_detached_4x4_view, :point => Point.new(2, 3), :on => false },
					{ :source => :a_detached_4x4_view, :point => Point.new(3, 3), :on => false }
				]
			)
		)
	end

	test "when an entire enabled view is refreshed the views view led refreshed actions should get notified of refreshed leds and their state" do
		view = @a_detached_4x4_view
		view_led_refreshed_listener = MockViewLedRefreshedListener.new(view)

		view.refresh

		assert(
			view_led_refreshed_listener.has_been_notified_of?(
				[
					{ :source => :a_detached_4x4_view, :point => Point.new(0, 0), :on => false },
					{ :source => :a_detached_4x4_view, :point => Point.new(1, 0), :on => false },
					{ :source => :a_detached_4x4_view, :point => Point.new(2, 0), :on => false },
					{ :source => :a_detached_4x4_view, :point => Point.new(3, 0), :on => false },
					{ :source => :a_detached_4x4_view, :point => Point.new(0, 1), :on => false },
					{ :source => :a_detached_4x4_view, :point => Point.new(1, 1), :on => false },
					{ :source => :a_detached_4x4_view, :point => Point.new(2, 1), :on => false },
					{ :source => :a_detached_4x4_view, :point => Point.new(3, 1), :on => false },
					{ :source => :a_detached_4x4_view, :point => Point.new(0, 2), :on => false },
					{ :source => :a_detached_4x4_view, :point => Point.new(1, 2), :on => false },
					{ :source => :a_detached_4x4_view, :point => Point.new(2, 2), :on => false },
					{ :source => :a_detached_4x4_view, :point => Point.new(3, 2), :on => false },
					{ :source => :a_detached_4x4_view, :point => Point.new(0, 3), :on => false },
					{ :source => :a_detached_4x4_view, :point => Point.new(1, 3), :on => false },
					{ :source => :a_detached_4x4_view, :point => Point.new(2, 3), :on => false },
					{ :source => :a_detached_4x4_view, :point => Point.new(3, 3), :on => false }
				]
			)
		)
	end

	test "refreshing a disabled view should throw an error" do
		view = @a_disabled_2x2_view

		assert_raise(RuntimeError) { view.refresh }
		assert_raise(RuntimeError) { view.refresh_bounds(Point.new(1, 1), 1, 1) }
		assert_raise(RuntimeError) { view.refresh_point(Point.new(0, 0)) }
	end

	test "when a disabled view is enabled it should be refreshed" do
		view = @a_disabled_2x2_view
		view_led_refreshed_listener = MockViewLedRefreshedListener.new(view)

		view.enable

		assert(
			view_led_refreshed_listener.has_been_notified_of?(
				[
					{ :source => :a_disabled_2x2_view, :point => Point.new(0, 0), :on => false },
					{ :source => :a_disabled_2x2_view, :point => Point.new(1, 0), :on => false },
					{ :source => :a_disabled_2x2_view, :point => Point.new(0, 1), :on => false },
					{ :source => :a_disabled_2x2_view, :point => Point.new(1, 1), :on => false },
				]
			)
		)
	end

	# string representations
	test "the string representation of a view should include id bounds and whether the view is enabled" do
		view = View.new_detached(4, 3)
		assert_equal(
			"a Grrr::View (4x3, enabled)",
			view.to_s
		)
		view.id = :test
		assert_equal(
			"a Grrr::View (test, 4x3, enabled)",
			view.to_s
		)
	end

	test "a plot of a view should describe where buttons and leds currently are pressed and lit" do
		view = MockOddColsLitView.new_detached(4, 3)

		view.press(Point.new(1, 2))
		view.press(Point.new(3, 0))

		assert_equal(
			"  0 1 2 3      0 1 2 3\n" +
			"0 - - - P    0 - L - L\n" +
			"1 - - - -    1 - L - L\n" +
			"2 - P - -    2 - L - L\n",
			view.to_plot
		)
	end

	test "a tree plot of a view should describe where buttons and leds currently are pressed and lit and also include its string representation" do
		view = View.new_detached(4, 3)
		assert_equal(
			"a Grrr::View (4x3, enabled)\n" +
			"  0 1 2 3      0 1 2 3\n" +
			"0 - - - -    0 - - - -\n" +
			"1 - - - -    1 - - - -\n" +
			"2 - - - -    2 - - - -\n" +
			"\n",
			view.to_tree(true)
		)
	end
end
