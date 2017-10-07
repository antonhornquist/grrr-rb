class TestMultiButtonView < Test::Unit::TestCase
	def setup
		save_globals
		disable_trace_and_flash
	end

	def teardown
		restore_globals
	end

	# initialization
	test "the button array size of a multibuttonview should by default be of the same size as the view" do
		view = MultiButtonView.new_detached(4, 4)

		assert_equal(
			view.button_array_size,
			[4, 4]
		)
	end

	# button array size
	test "it should be possible to change the button array size of a multibuttonview" do
		view = MultiButtonView.new_detached(4, 4)
		view.button_array_size = [2, 2]

		assert_equal(
			view.button_array_size,
			[2, 2]
		)
	end

	test "it should not be possible to change the button array size of a multibuttonview so that num_cols of the view is not divisable by num_button_cols" do
		view = MultiButtonView.new_detached(4, 4)

		assert_raise(RuntimeError) { view.button_array_size = [3, 2] }
	end

	test "it should not be possible to change the button array size of a multibuttonview so that num_rows of the view is not divisable by num_button_rows" do
		view = MultiButtonView.new_detached(4, 4)

		assert_raise(RuntimeError) { view.button_array_size = [2, 3] }
	end

	# value
	test "the value of a multibuttonview should be a map of the value of its buttons" do
		view = MultiButtonView.new_detached(4, 4)

		assert_equal(
			view.value,
			[
				[false, false, false, false],
				[false, false, false, false],
				[false, false, false, false],
				[false, false, false, false]
			]
		)
	end

	test "when a multibuttonview's value is updated by a call to value_action a main action notification should be sent" do
		view = MultiButtonView.new_detached(2, 2)
		listener = MockActionListener.new(view)

		view.value_action = [
			[false, true],
			[false, true]
		]

		assert(
			listener.has_been_notified_of?(
				[
					[
						view,
						[
							[false, true],
							[false, true],
						]
					]
				]
			)
		)
	end

	test "when a multibuttonview's value is updated by a call to value_action button value changed notifications should be sent for all buttons whose value has changed" do
		view = MultiButtonView.new_detached(2, 2)
		listener = MockButtonValueChangedListener.new(view)

		view.value_action = [
			[false, true],
			[false, true]
		]


		assert(
			listener.has_been_notified_of?(
				[
					{
						:view => view,
						:x => 0,
						:y => 1,
						:val => true
					},
					{
						:view => view,
						:x => 1,
						:y => 1,
						:val => true
					}
				]
			)
		)
	end

	# button events
	test "when a multibuttonview's value is updated by a button event a main action notification should be sent" do
		view = MultiButtonView.new_detached(2, 2)
		listener = MockActionListener.new(view)

		view.press(Point.new(0, 0))

		assert(
			listener.has_been_notified_of?(
				[
					[
						view,
						[
							[true, false],
							[false, false],
						]
					]
				]
			)
		)
	end

	test "when a multibuttonview's value is updated by a button event a button value changed notification should be sent" do
		view = MultiButtonView.new_detached(2, 2)
		listener = MockButtonValueChangedListener.new(view)

		view.press(Point.new(0, 0))

		assert(
			listener.has_been_notified_of?(
				[
					{
						:view => view,
						:x => 0,
						:y => 0,
						:val => true
					}
				]
			)
		)
	end

	# string representation
	test "the plot of a multibuttonview should not indicate its internal child views" do
		view = MultiButtonView.new_detached(4, 4)

		assert_equal(
			"  0 1 2 3      0 1 2 3\n" +
			"0 - - - -    0 - - - -\n" +
			"1 - - - -    1 - - - -\n" +
			"2 - - - -    2 - - - -\n" +
			"3 - - - -    3 - - - -\n",
			view.to_plot
		)
	end
end
