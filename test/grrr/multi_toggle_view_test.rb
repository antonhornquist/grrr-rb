class TestMultiToggleView < Test::Unit::TestCase
	def setup
		save_globals
		disable_trace_and_flash
	end

	def teardown
		restore_globals
	end

	# initialization
	test "the number of toggles in a vertical multitoggleview should by default be the same as the number of columns in its view" do
		view = MultiToggleView.new_detached(8, 4, :vertical)

		assert_equal(
			view.num_toggles,
			8
		)
	end

	test "the number of toggles in a horizontal multitoggleview should by default be the same as the number of rows in its view" do
		view = MultiToggleView.new_detached(8, 4, :horizontal)

		assert_equal(
			view.num_toggles,
			4
		)
	end

	# number of toggles
	test "it should be possible to change the number of toggles in a multitoggleview" do
		view = MultiToggleView.new_detached(4, 4, :vertical)
		view.num_toggles = 2

		assert_equal(
			view.num_toggles,
			2
		)
	end

	test "it should not be possible to change the number of toggles in a vertical multitoggleview so that num_cols of the view is not divisable by num_toggles" do
		view = MultiToggleView.new_detached(8, 7, :vertical)

		assert_raise(RuntimeError) { view.num_toggles = 7 }
	end

	test "it should not be possible to change the number of toggles in a horizontal multitoggleview so that num_rows of the view is not divisable by num_toggles" do
		view = MultiToggleView.new_detached(3, 4, :horizontal)

		assert_raise(RuntimeError) { view.num_toggles = 3 }
	end

	# orientation
	test "it should be possible to change the orientation of a multitoggleview" do
 		view = MultiToggleView.new_detached(7, 4, :horizontal)
 		assert_nothing_raised { view.orientation = :vertical }
	end

	test "when orientation of a multitoggleview is changed num_toggles should be se as default" do
 		view = MultiToggleView.new_detached(7, 4, :horizontal)
 		view.orientation = :vertical

		assert_equal(view.num_toggles, 7)
	end

	# value
	test "the value of a multitoggleview should be a map of the value of its toggles" do
		view = MultiToggleView.new_detached(4, 4, :horizontal)

		assert_equal(
			view.value,
			[0, 0, 0, 0]
		)
	end

	test "when a multitoggleview's value is updated by a call to value_action a main action notification should be sent" do
		view = MultiToggleView.new_detached(4, 4, :horizontal)
		listener = MockActionListener.new(view)

		view.value_action = [1, 0, 2, 0]

		assert(
			listener.has_been_notified_of?(
				[
					[
						view,
						[1, 0, 2, 0]
					]
				]
			)
		)
	end

	test "when a multitoggleview's value is updated by a call to value_action toggle value changed notifications should be sent for all toggles whose value has changed" do
		view = MultiToggleView.new_detached(4, 4, :horizontal)
		listener = MockToggleValueChangedListener.new(view)

		view.value_action = [1, 0, 2, 0]

		assert(
			listener.has_been_notified_of?(
				[
					{
						:multi_toggle_view => view,
						:i => 0,
						:value => 1
					},
					{
						:multi_toggle_view => view,
						:i => 2,
						:value => 2
					}
				]
			)
		)
	end

	# button events
	test "when a multitoggleview's value is updated by a button event a main action notification should be sent" do
		view = MultiToggleView.new_detached(4, 4, :horizontal)
		listener = MockActionListener.new(view)

		view.press(Point.new(3, 1))

		assert(
			listener.has_been_notified_of?(
				[
					[
						view,
						[0, 3, 0, 0]
					]
				]
			)
		)
	end

	test "when a multitoggleview's value is updated by a button event a button value changed notification should be sent" do
		view = MultiToggleView.new_detached(4, 4, :horizontal)
		listener = MockToggleValueChangedListener.new(view)

		view.press(Point.new(3, 1))

		assert(
			listener.has_been_notified_of?(
				[
					{
						:multi_toggle_view => view,
						:i => 1,
						:value => 3
					}
				]
			)
		)
	end

	# string representation
	test "the plot of a multitoggleview should not indicate its internal child views" do
		view = MultiToggleView.new_detached(4, 4, :vertical)

		assert_equal(
			"  0 1 2 3      0 1 2 3\n" +
			"0 - - - -    0 L L L L\n" +
			"1 - - - -    1 - - - -\n" +
			"2 - - - -    2 - - - -\n" +
			"3 - - - -    3 - - - -\n",
			view.to_plot
		)
	end
end
