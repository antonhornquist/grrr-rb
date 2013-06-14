class TestSwitcher < Test::Unit::TestCase
	def setup
		save_globals
		disable_trace_and_flash
		@switcher = Switcher.new_detached(4, 4)
	end

	def teardown
		restore_globals
	end

	# test helpers
	def assert_switcher_is_parent_of_view(switcher, view)
		assert(switcher.is_parent_of?(view))
		assert_equal( switcher, view.parent )
		assert(view.has_parent?)
		assert_equal( false, view.is_detached? )
	end

	def assert_switcher_is_not_parent_of_view(switcher, view)
		assert_equal( false, switcher.is_parent_of?(view) )
		assert_equal( nil, view.parent )
		assert_equal( false, view.has_parent? )
		assert(view.is_detached?)
	end

	# parent - child
	test "it should be possible to attach a child view to a switcher on creation of the child view" do
		switcher = @switcher
		view1 = View.new(switcher, Point.new(0, 0), 2, 2)
		view2 = View.new(switcher, Point.new(2, 2), 2, 2)

		assert_switcher_is_parent_of_view(switcher, view1)
		assert_equal(Point.new(0, 0), view1.origin)
		assert_switcher_is_parent_of_view(switcher, view2)
		assert_equal(Point.new(2, 2), view2.origin)
	end

	test "it should be possible to attach a detached view as a child to a switcher" do
		switcher = @switcher
		view1 = View.new_detached(2, 2)
		view2 = View.new_detached(2, 2)

		switcher.add_child(view1, Point.new(0, 0))
		switcher.add_child(view2, Point.new(2, 2))

		assert_switcher_is_parent_of_view(switcher, view1)
		assert_equal(Point.new(0, 0), view1.origin)
		assert_switcher_is_parent_of_view(switcher, view2)
		assert_equal(Point.new(2, 2), view2.origin)
	end

	test "it should be possible to remove child views from a switcher" do
		switcher = @switcher
		view1 = View.new_detached(2, 2)
		view2 = View.new_detached(2, 2)
		switcher.add_child(view1, Point.new(0, 0))
		switcher.add_child(view2, Point.new(2, 2))

		switcher.remove_child(view1)
		switcher.remove_child(view2)

		assert_switcher_is_not_parent_of_view(switcher, view1)
		assert_switcher_is_not_parent_of_view(switcher, view2)
	end

	test "when a view is added as child to an empty switcher the view should be set as current view" do
		switcher = @switcher

		view = View.new(switcher, Point.new(0, 0), 2, 2)

		assert_equal(view, switcher.current_view)
	end

	test "when a view is added as child to a non empty switcher current view should be unchanged" do
		switcher = @switcher
		view1 = View.new(switcher, Point.new(0, 0), 4, 4)

		view2 = View.new(switcher, Point.new(0, 0), 4, 4)

		assert_equal(view1, switcher.current_view)
	end

	test "when an enabled child view is added to a non empty switcher it should be disabled" do
		switcher = @switcher
		view1 = View.new(switcher, Point.new(0, 0), 4, 4)
		view2 = View.new(switcher, Point.new(0, 0), 4, 4)

		assert(view2.is_disabled?)
	end

	test "an empty switcher should have a value of nil" do
		switcher = @switcher

		assert_equal(nil, switcher.value)
	end

	test "a non empty switchers value should be the same as the index of the current view among all the child views" do
		switcher = @switcher
		view1 = View.new(switcher, Point.new(0, 0), 4, 4)
		view2 = View.new(switcher, Point.new(0, 0), 4, 4)

		assert_equal(0, switcher.value)
	end

	test "when a switcher is emptied after removal of view switchers value should have changed to nil" do
		switcher = @switcher
		view = View.new(switcher, Point.new(0, 0), 2, 2)

		view.remove

		assert_equal(nil, switcher.value)
	end

	test "when switcher is non empty after removal of current view the child view prior to current view or first child view should be set as current view" do
		switcher = @switcher
		view1 = View.new(switcher, Point.new(0, 0), 4, 4)
		view2 = View.new(switcher, Point.new(0, 0), 4, 4)
		view3 = View.new(switcher, Point.new(0, 0), 4, 4)
		switcher.value = 2

		switcher.remove_child(view3)

		assert(view2, switcher.current_view)

		view4 = View.new(switcher, Point.new(0, 0), 4, 4)
		switcher.value = 0

		switcher.remove_child(view1)

		assert(view2, switcher.current_view)
	end

	test "it should not be possible to disable a child view of a switcher" do
		switcher = @switcher
		view = View.new(switcher, Point.new(0, 0), 4, 4)

		assert_raise(RuntimeError) { view.disable }
	end

	test "it should not be possible to enable a child view of a switcher" do
		switcher = @switcher
		view1 = View.new(switcher, Point.new(0, 0), 2, 2)
		view2 = View.new(switcher, Point.new(2, 2), 2, 2)

		assert_raise(RuntimeError) { view2.enable }
	end

	# view switching
	test "it should be possible to switch between views by index" do
		switcher = @switcher
		child1 = View.new(switcher, Point.new(0, 0), 4, 4)
		child2 = View.new_disabled(switcher, Point.new(0, 0), 4, 4)

		switcher.value = 1

		assert_equal(child2, switcher.current_view)
	end

	test "when views are switched the previous current view should be disabled and the new one enabled" do
		switcher = @switcher
		child1 = View.new(switcher, Point.new(0, 0), 4, 4)
		child2 = View.new_disabled(switcher, Point.new(0, 0), 4, 4)

		switcher.value = 1

		assert(child1.is_disabled?)
		assert(child2.is_enabled?)
	end

	test "it should not be possible to switch to a view index out of bounds" do
		switcher = @switcher
		child1 = View.new(switcher, Point.new(0, 0), 4, 4)
		child2 = View.new_disabled(switcher, Point.new(0, 0), 4, 4)

		assert_raise(RuntimeError) { switcher.value = 2 }
	end

	test "it should not be possible to set a switcher value to nil" do
		switcher = @switcher
		child1 = View.new(switcher, Point.new(0, 0), 4, 4)
		child2 = View.new_disabled(switcher, Point.new(0, 0), 4, 4)

		assert_raise(RuntimeError) { switcher.value = nil }
	end

	test "it should be possible to switch between views by view" do
		switcher = @switcher
		child1 = View.new(switcher, Point.new(0, 0), 4, 4)
		child2 = View.new_disabled(switcher, Point.new(0, 0), 4, 4)

		switcher.switch_to_view(child2)

		assert_equal(child2, switcher.current_view)
	end

	test "it should not be possible to switch between views by view to a view that is not a children of switcher" do
		switcher = @switcher
		child = View.new(switcher, Point.new(0, 0), 4, 4)
		detached_view = View.new_detached(4, 4)

		assert_raise(RuntimeError) { switcher.switch_to_view(detached_view) }
	end

	test "assuming a switchers children have unique ids it should be possible to switch between views by id" do
		switcher = @switcher
		child1 = View.new(switcher, Point.new(0, 0), 4, 4)
		child1.id = :one
		child2 = View.new_disabled(switcher, Point.new(0, 0), 4, 4)
		child2.id = :two

		switcher.switch_to(:two)

		assert_equal(child2, switcher.current_view)
	end

	test "if a switchers children do not have unique ids it should not be possible to switch between views by id" do
		switcher = @switcher
		child1 = View.new(switcher, Point.new(0, 0), 4, 4)
		child1.id = :one
		child2 = View.new_disabled(switcher, Point.new(0, 0), 4, 4)
		child2.id = :one

		assert_raise(RuntimeError) { switcher.switch_to(:one) }
	end

	test "it should not be possible to switch views by id if no child has the specified id" do
		switcher = @switcher
		child1 = View.new(switcher, Point.new(0, 0), 4, 4)
		child1.id = :one
		child2 = View.new_disabled(switcher, Point.new(0, 0), 4, 4)
		child2.id = :two

		assert_raise(RuntimeError) { switcher.switch_to(:three) }
	end

	test "it should be possible to switch views while a button on switcher view is pressed" do
		View.new(@switcher, Point.new(0, 0), 4, 4)
		View.new_disabled(@switcher, Point.new(0, 0), 4, 4)
		@switcher.press(Point.new(2, 2))

		@switcher.value = 1

		assert_nothing_raised { @switcher.release(Point.new(2, 2)) }
	end
end
