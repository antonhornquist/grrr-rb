class TestTopView < Test::Unit::TestCase
	def setup
		save_globals
		disable_trace_and_flash
	end

	def teardown
		restore_globals
	end

	# parent - child
	test "it should not be possible to add a top view as a child to another view" do
		container_view = ContainerView.new_detached(8, 8)
		top_view = TopView.new(8, 8)

		assert_raise(RuntimeError) {
			container_view.add_child(top_view, Point.new(0, 0))
		}
	end

	# button events and state
	test "a top view button should be considered pressed when one or many sources have emitted button press events to it" do
		top_view = TopView.new(8, 8)
		mock_controller_1 = MockController.new(8, 8, top_view, Point.new(0, 0))
		mock_controller_2 = MockController.new(4, 4, top_view, Point.new(2, 2))
		view_button_state_changed_listener = MockViewButtonStateChangedListener.new(top_view)

		mock_controller_1.emulate_press(Point.new(2, 2))

		assert(top_view.is_pressed_at?(Point.new(2, 2)))
		assert(
			view_button_state_changed_listener.has_been_notified_of?(
				[
					{ :point => Point.new(2, 2), :pressed => true }
				]
			)
		)

		view_button_state_changed_listener.reset_notifications

		mock_controller_2.emulate_press(Point.new(0, 0))

		assert(top_view.is_pressed_at?(Point.new(2, 2)))
		assert(view_button_state_changed_listener.has_not_been_notified_of_anything?)
	end

	test "a top view button should not be considered released until all sources that pressed the button have emitted button release events to it" do
		top_view = TopView.new(8, 8)
		mock_controller_1 = MockController.new(8, 8, top_view, Point.new(0, 0))
		mock_controller_2 = MockController.new(4, 4, top_view, Point.new(2, 2))
		mock_controller_1.emulate_press(Point.new(2, 2))
		mock_controller_2.emulate_press(Point.new(0, 0))
		view_button_state_changed_listener = MockViewButtonStateChangedListener.new(top_view)

		mock_controller_1.emulate_release(Point.new(2, 2))

		assert(top_view.is_pressed_at?(Point.new(2, 2)))
		assert(view_button_state_changed_listener.has_not_been_notified_of_anything?)

		mock_controller_2.emulate_release(Point.new(0, 0))

		assert(top_view.is_released_at?(Point.new(2, 2)))
		assert(
			view_button_state_changed_listener.has_been_notified_of?(
				[
					{ :point => Point.new(2, 2), :pressed => false }
				]
			)
		)
	end
end
