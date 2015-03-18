class Controller
	class << self
		attr_writer :all
	end
end

class TestController < Test::Unit::TestCase
	def setup
		save_globals
		disable_trace_and_flash
	end

	def teardown
		restore_globals
		Controller.all = []
	end

	# initialization
	test "a controller should by default create a new top view of same bounds as controller if no view is supplied during creation" do
		mock_controller = MockController.new(8, 8)

		assert(mock_controller.is_attached?)
		assert_equal(
			mock_controller.num_cols,
			mock_controller.view.num_cols
		)
		assert_equal(
			mock_controller.num_rows,
			mock_controller.view.num_rows
		)
		assert_equal(
			Point.new(0, 0),
			mock_controller.origin
		)
	end

	test "it should be possible to override default creation of new top view in order to create a detached controller" do
		mock_controller = MockController.new(8, 8, nil, nil, false)

		assert(mock_controller.is_detached?)
	end

	test "it should be possible to create a new detached controller from scratch" do
		mock_controller = MockController.new_detached(8, 8)

		assert(mock_controller.is_detached?)
	end	

	test "it should be possible to attach a controller to an existing view during creation of the controller" do
		view = View.new_detached(4, 4)

		mock_controller = MockController.new(4, 4, view, Point.new(0, 0))

		assert(mock_controller.is_attached?)
		assert_equal(
			view,
			mock_controller.view
		)
	end	

	test "all created controllers should be available in a controller collection class variable" do
		mock_controller_1 = MockController.new(8, 8)
		mock_controller_2 = MockController.new(3, 8)
		mock_controller_3 = MockController.new(3, 3)
		mock_controller_4 = MockController.new(1, 6)

		assert_equal(
			[mock_controller_1, mock_controller_2, mock_controller_3, mock_controller_4],
			Controller.all
		)
	end

	test "when a controller is created init_action should be invoked" do
		result = nil
		Controller.init_action = lambda { |controller|
			result = controller
		}

		mock_controller = MockController.new(8, 8)

		assert_equal(
			mock_controller, 
			result
		)
	end

	# controller info
	test "it should be possible to retrieve setup info for controller" do
		mock_controller = MockController.new_detached(4, 4)

		assert_equal(
			"[Description of MockController Settings]",
			mock_controller.info
		)
	end

	# attach / detach view
	test "it should be possible to attach a detached controller to a view of same bounds as controller" do
		view = View.new_detached(4, 4)
		mock_controller = MockController.new_detached(4, 4)

		mock_controller.attach(view, Point.new(0, 0))

		assert(mock_controller.is_attached?)
		assert_equal(
			view,
			mock_controller.view
		)
	end

	test "it should be possible to attach a detached controller to a view that is larger than the controller as long as the controller is within view bounds" do
		view = View.new_detached(8, 8)
		mock_controller = MockController.new_detached(4, 4)

		mock_controller.attach(view, Point.new(2, 2))

		assert(mock_controller.is_attached?)
		assert_equal(
			view,
			mock_controller.view
		)
	end

	test "if a controller that is attached to a view at a specific origin is out of bounds of the view an error should occur" do
		view = View.new_detached(4, 4)
		mock_controller = MockController.new_detached(4, 4)

		assert_raise(RuntimeError) { 
			mock_controller.attach(view, Point.new(2, 2))
		}
	end

	test "attaching a view to an already attached controller should throw an error" do
		view1 = View.new_detached(4, 4)
		view2 = View.new_detached(4, 4)
		mock_controller = MockController.new_detached(4, 4)

		mock_controller.attach(view1, Point.new(0, 0))

		assert_raise(RuntimeError) { 
			mock_controller.attach(view2, Point.new(0, 0))
		}
	end

	test "it should be possible to detach an attached controller from a view" do
		view = View.new_detached(4, 4)
		mock_controller = MockController.new(4, 4, view, Point.new(0, 0))

		mock_controller.detach

		assert(mock_controller.is_detached?)
		assert_equal(
			nil,
			mock_controller.view
		)
	end

	test "detaching an already detached controller should throw an error" do
		mock_controller = MockController.new_detached(4, 4)

		assert_raise(RuntimeError) { mock_controller.detach }
	end

	# button and led state
	test "the led state of an attached controller should match the led state of the attached view" do
		view = MockOddColsLitView.new_detached(4, 4)
		mock_controller = MockController.new(2, 2, view, Point.new(1, 1))

		assert_equal( true, mock_controller.is_lit_at?(Point.new(0, 0)) )
		assert_equal( false, mock_controller.is_lit_at?(Point.new(1, 0)) )
		assert_equal( true, mock_controller.is_lit_at?(Point.new(0, 1)) )
		assert_equal( false, mock_controller.is_lit_at?(Point.new(1, 1)) )
	end

	test "all leds of a detached controller should be unlit" do
		mock_controller = MockController.new_detached(2, 2)

		assert_equal( false, mock_controller.is_lit_at?(Point.new(0, 0)) )
		assert_equal( false, mock_controller.is_lit_at?(Point.new(1, 0)) )
		assert_equal( false, mock_controller.is_lit_at?(Point.new(0, 1)) )
		assert_equal( false, mock_controller.is_lit_at?(Point.new(1, 1)) )
	end

	test "an out of bounds led state check should throw an error" do
		mock_controller = MockController.new(4, 4)

		assert_raise(RuntimeError) {
			mock_controller.is_lit_at?(Point.new(4, 4))
		}
	end

	test "the button state of an attached controller should match the button state of the attached view" do
		view = MockOddColsLitView.new_detached(4, 4)
		mock_controller = MockController.new(2, 2, view, Point.new(1, 1))

		view.press(Point.new(1, 2))
		view.press(Point.new(2, 2))

		assert_equal( false, mock_controller.is_pressed_at?(Point.new(0, 0)) )
		assert_equal( false, mock_controller.is_pressed_at?(Point.new(1, 0)) )
		assert_equal( true, mock_controller.is_pressed_at?(Point.new(0, 1)) )
		assert_equal( true, mock_controller.is_pressed_at?(Point.new(1, 1)) )
	end

	test "all buttons of a detached controller should be released" do
		mock_controller = MockController.new_detached(2, 2)

		assert_equal( false, mock_controller.is_pressed_at?(Point.new(0, 0)) )
		assert_equal( false, mock_controller.is_pressed_at?(Point.new(1, 0)) )
		assert_equal( false, mock_controller.is_pressed_at?(Point.new(0, 1)) )
		assert_equal( false, mock_controller.is_pressed_at?(Point.new(1, 1)) )
	end

	test "an out of bounds button state check should throw an error" do
		mock_controller = MockController.new(4, 4)

		assert_raise(RuntimeError) {
			mock_controller.is_pressed_at?(Point.new(4, 4))
		}
	end

	# emit button events
	test "when a controller is pressed it should emit button events to its attached view" do
		view = View.new_detached(8, 8)
		mock_controller = MockController.new(4, 4, view, Point.new(1, 1))

		mock_controller.emulate_press(Point.new(2, 3))

		assert(view.is_pressed_at?(Point.new(3, 4)))
	end

	test "emitting a button event out of bounds of controller should throw an error" do
		view = View.new_detached(8, 8)
		mock_controller = MockController.new(4, 4, view, Point.new(2, 2))

		assert_raise(RuntimeError) {
			mock_controller.emulate_press(Point.new(4, 4))
		}
	end

	# refreshing controller
	test "it should be possible to refresh a controller that is attached to a view" do
		view = MockOddColsLitView.new_detached(4, 4)
		mock_controller = MockController.new(2, 2, view, Point.new(1, 1))

		mock_controller.refresh

		assert_equal(
			[	
				{ :point => Point.new(0, 0), :on => true },
				{ :point => Point.new(1, 0), :on => false },
				{ :point => Point.new(0, 1), :on => true },
				{ :point => Point.new(1, 1), :on => false },
			],
			mock_controller.view_led_refreshed_notifications
		)
	end

	test "it should be possible to refresh a detached controller" do
		mock_controller = MockController.new_detached(2, 2)

		mock_controller.refresh

		assert_equal(
			[	
				{ :point => Point.new(0, 0), :on => false },
				{ :point => Point.new(1, 0), :on => false },
				{ :point => Point.new(0, 1), :on => false },
				{ :point => Point.new(1, 1), :on => false },
			],
			mock_controller.view_led_refreshed_notifications
		)
	end

	test "when a controller is attached to a view the controller should be refreshed with the led state of the attached view" do
		view = MockOddColsLitView.new_detached(4, 4)
		mock_controller = MockController.new_detached(2, 2)

		mock_controller.attach(view, Point.new(1, 1))

		assert_equal(
			[	
				{ :point => Point.new(0, 0), :on => true },
				{ :point => Point.new(1, 0), :on => false },
				{ :point => Point.new(0, 1), :on => true },
				{ :point => Point.new(1, 1), :on => false },
			],
			mock_controller.view_led_refreshed_notifications
		)
	end

	test "when a controller is detached from a view the controller should be refreshed" do
		view = MockOddColsLitView.new_detached(4, 4)
		mock_controller = MockController.new(2, 2, view, Point.new(1, 1))

		mock_controller.detach

		assert_equal(
			[	
				{ :point => Point.new(0, 0), :on => false },
				{ :point => Point.new(1, 0), :on => false },
				{ :point => Point.new(0, 1), :on => false },
				{ :point => Point.new(1, 1), :on => false },
			],
			mock_controller.view_led_refreshed_notifications
		)
	end

	# removal
	test "when a controller is removed it should no be available in the controller collection class variable" do
		mock_controller_1 = MockController.new(8, 8)
		mock_controller_2 = MockController.new(3, 8)
		mock_controller_3 = MockController.new(3, 3)
		mock_controller_4 = MockController.new(1, 6)

		mock_controller_3.remove

		assert_equal(
			[mock_controller_1, mock_controller_2, mock_controller_4],
			Controller.all
		)
	end

	test "when a controller is removed it should get detached from its top view" do
		mock_controller = MockController.new(8, 8)

		mock_controller.remove

		assert(
			mock_controller.is_detached?
		)
	end

	test "when a controller is removed it should invoke on_remove action" do
		result = nil
		mock_controller = MockController.new(8, 8)
		mock_controller.on_remove = lambda {
			result = "i've been removed"
		}

		mock_controller.remove

		assert_equal(
			"i've been removed",
			result
		)
	end

	# view events
	test "when a view attached to a controller is refreshed controller should receive notifications of refreshed leds within the controllers bounds" do
		view = MockOddColsLitView.new_detached(4, 4)
		mock_controller = MockController.new(2, 2, view, Point.new(1, 1))

		view.refresh

		assert_equal(
			[	
				{ :point => Point.new(0, 0), :on => true },
				{ :point => Point.new(1, 0), :on => false },
				{ :point => Point.new(0, 1), :on => true },
				{ :point => Point.new(1, 1), :on => false },
			],
			mock_controller.view_led_refreshed_notifications
		)
	end

	test "when a view attached to a controller receives button events within the controllers bounds the controller should receive notifications of changes in button state" do
		view = View.new_detached(4, 4)
		mock_controller = MockController.new(3, 3, view, Point.new(1, 1))

		view.press(Point.new(0, 0)) # not within controller bounds
		view.press(Point.new(0, 1)) # not within controller bounds
		view.press(Point.new(1, 0)) # not within controller bounds
		view.press(Point.new(2, 3))
		view.press(Point.new(3, 3))
		view.release(Point.new(2, 3))
		view.release(Point.new(3, 3))

		assert_equal(
			[	
				{ :point => Point.new(1, 2), :pressed => true },
				{ :point => Point.new(2, 2), :pressed => true },
				{ :point => Point.new(1, 2), :pressed => false },
				{ :point => Point.new(2, 2), :pressed => false },
			],
			mock_controller.view_button_state_changed_notifications
		)
	end
end
