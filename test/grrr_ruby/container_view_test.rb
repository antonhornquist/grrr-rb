include Grrr

class TestContainerView < Test::Unit::TestCase
	def setup
		save_globals
		disable_trace_and_flash
		top_container = ContainerView.new_detached(4, 4)
		top_container.id = :top_container
		child_container = ContainerView.new(top_container, Point.new(1, 1), 3, 3)
		child_container.id = :child_container
		view = View.new(child_container, Point.new(1, 1), 2, 2)
		view.id = :view
		@view_tree = [top_container, child_container, view]
	end

	def teardown
		restore_globals
	end

	# test helpers
	def assert_container_is_parent_of_view(container, view)
		assert(container.is_parent_of?(view))
		assert_equal( container, view.parent )
		assert(view.has_parent?)
		assert_equal( false, view.is_detached? )
	end

	# parent - child
	test "it should be possible to attach a child view to a container view on creation of the child view using a point defined in a string" do
		container = ContainerView.new_detached(4, 4)
		view1 = View.new(container, "0@0", 2, 2)
		view2 = View.new(container, "2@2", 2, 2)

		assert_container_is_parent_of_view(container, view1)
		assert_equal(Point.new(0, 0), view1.origin)
		assert_container_is_parent_of_view(container, view2)
		assert_equal(Point.new(2, 2), view2.origin)
	end

	test "it should be possible to attach a detached view as a child to a container view" do
		container = ContainerView.new_detached(4, 4)
		view1 = View.new_detached(2, 2)
		view2 = View.new_detached(2, 2)

		container.add_child(view1, "0@0")
		container.add_child(view2, "2@2")

		assert_container_is_parent_of_view(container, view1)
		assert_equal(Point.new(0, 0), view1.origin)
		assert_container_is_parent_of_view(container, view2)
		assert_equal(Point.new(2, 2), view2.origin)
	end
end
