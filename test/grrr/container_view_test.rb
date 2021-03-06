class TestContainerView < Test::Unit::TestCase
	def setup
		save_globals
		disable_trace_and_flash
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

	def assert_container_is_not_parent_of_view(container, view)
		assert_equal( false, container.is_parent_of?(view) )
		assert_equal( nil, view.parent )
		assert_equal( false, view.has_parent? )
		assert(view.is_detached?)
	end

	# validations
	test "it should be possible to determine whether a view would contain another view at a specific origin" do
		container = Grrr::ContainerView.new_detached(2, 3)
		view = Grrr::View.new_detached(2, 2)
		assert(container.is_within_bounds?(view, Grrr::Point.new(0, 0)))
		assert_equal(false, container.is_within_bounds?(view, Grrr::Point.new(2, 2)))
		assert_nothing_raised { container.validate_within_bounds(view, Grrr::Point.new(0, 0)) }
		assert_raise(RuntimeError) { container.validate_within_bounds(view, Grrr::Point.new(2, 2)) }
	end

	test "it should be possible to determine whether a container is parent of a view" do
		container = Grrr::ContainerView.new_detached(2, 2)
		view1 = Grrr::View.new(container, Grrr::Point.new(0, 0), 2, 2)
		view2 = Grrr::View.new_detached(2, 2)
		assert_nothing_raised { container.validate_parent_of(view1) }
		assert_raise(RuntimeError) { container.validate_parent_of(view2) }
	end

	test "if a container has no children it should be considered empty" do
		container = Grrr::ContainerView.new_detached(2, 2)

		assert(container.is_empty?)
	end

	test "if a container has one or more children it should not be considered empty" do
		container = Grrr::ContainerView.new_detached(2, 2)
		Grrr::View.new(container, Grrr::Point.new(0, 0), 2, 2)

		assert_equal(false, container.is_empty?)
	end

	# parent - child
	test "it should be possible to attach a child view to a container view on creation of the child view" do
		container = Grrr::ContainerView.new_detached(4, 4)
		view1 = Grrr::View.new(container, Grrr::Point.new(0, 0), 2, 2)
		view2 = Grrr::View.new(container, Grrr::Point.new(2, 2), 2, 2)

		assert_container_is_parent_of_view(container, view1)
		assert_equal(Grrr::Point.new(0, 0), view1.origin)
		assert_container_is_parent_of_view(container, view2)
		assert_equal(Grrr::Point.new(2, 2), view2.origin)
	end

	test "it should be possible to attach a child view to a container view on creation of the child view using a point defined in a string" do # to specify a point as a string is ruby specific to have something equivalent to SuperCollider point shortcut
		container = Grrr::ContainerView.new_detached(4, 4)
		view1 = Grrr::View.new(container, "0@0", 2, 2)
		view2 = Grrr::View.new(container, "2@2", 2, 2)

		assert_container_is_parent_of_view(container, view1)
		assert_equal(Grrr::Point.new(0, 0), view1.origin)
		assert_container_is_parent_of_view(container, view2)
		assert_equal(Grrr::Point.new(2, 2), view2.origin)
	end

	test "it should be possible to attach a detached view as a child to a container view" do
		container = Grrr::ContainerView.new_detached(4, 4)
		view1 = Grrr::View.new_detached(2, 2)
		view2 = Grrr::View.new_detached(2, 2)

		container.add_child(view1, Grrr::Point.new(0, 0))
		container.add_child(view2, Grrr::Point.new(2, 2))

		assert_container_is_parent_of_view(container, view1)
		assert_equal(Grrr::Point.new(0, 0), view1.origin)
		assert_container_is_parent_of_view(container, view2)
		assert_equal(Grrr::Point.new(2, 2), view2.origin)
	end

	test "it should be possible to attach a detached view as a child to a container view using a point defined in a string" do # to specify a point as a string is ruby specific to have something equivalent to SuperCollider point shortcut
		container = Grrr::ContainerView.new_detached(4, 4)
		view1 = Grrr::View.new_detached(2, 2)
		view2 = Grrr::View.new_detached(2, 2)

		container.add_child(view1, "0@0")
		container.add_child(view2, "2@2")

		assert_container_is_parent_of_view(container, view1)
		assert_equal(Grrr::Point.new(0, 0), view1.origin)
		assert_container_is_parent_of_view(container, view2)
		assert_equal(Grrr::Point.new(2, 2), view2.origin)
	end

	test "it should not be possible to attach a parent of a container view as its child view" do
		parent_container = Grrr::ContainerView.new_detached(4, 4)
		container = Grrr::ContainerView.new(parent_container, Grrr::Point.new(0, 0), 4, 4)
		assert_raise(RuntimeError) { container.add_child(parent_container, Grrr::Point.new(0, 0)) }
	end

	test "it should be possible to remove child views from a container view" do
		container = Grrr::ContainerView.new_detached(4, 4)
		view1 = Grrr::View.new_detached(2, 2)
		view2 = Grrr::View.new_detached(2, 2)
		container.add_child(view1, Grrr::Point.new(0, 0))
		container.add_child(view2, Grrr::Point.new(2, 2))

		container.remove_child(view1)
		view2.remove

		assert_container_is_not_parent_of_view(container, view1)
		assert_container_is_not_parent_of_view(container, view2)
	end

	test "it should be possible to remove all child views of a container view" do
		container = Grrr::ContainerView.new_detached(4, 4)
		Grrr::View.new(container, Grrr::Point.new(0, 0), 2, 2)
		Grrr::View.new(container, Grrr::Point.new(2, 0), 2, 2)
		Grrr::View.new(container, Grrr::Point.new(2, 2), 2, 2)
		Grrr::View.new(container, Grrr::Point.new(0, 2), 2, 2)

		container.remove_all_children

		assert(container.is_empty?)
	end

	test "a detached view should not have a parent" do
		assert_equal(nil, Grrr::View.new_detached(4, 4).parent)
	end

	test "a detached view should not have an origin" do
		assert_equal(nil, Grrr::View.new_detached(4, 4).origin)
	end

	test "both parent and origin should be required in order to attach a child view to a container view on creation of the child view" do
		assert_raise(RuntimeError) { Grrr::View.new(nil, Grrr::Point.new(0, 0)) }
		assert_raise(RuntimeError) { Grrr::View.new(Grrr::View.new_detached, nil) }
	end

	test "an origin should be required when attaching a detached view to a container view" do
		container = Grrr::ContainerView.new_detached(4, 4)
		view = Grrr::View.new_detached(2, 2)
		assert_raise(RuntimeError) { container.add_child(view, nil) }
	end

	test "trying to remove a detached view should throw an error" do
		assert_raise(RuntimeError) { Grrr::View.new_detached(4, 4).remove }
	end

	test "it should be possible to determine whether any enabled or disabled child views cover a specific point" do
		container = Grrr::ContainerView.new_detached(4, 4)
		Grrr::View.new(container, Grrr::Point.new(1, 1), 2, 2)
		Grrr::View.new_disabled(container, Grrr::Point.new(2, 2), 2, 2)

		assert(container.has_child_at?(Grrr::Point.new(2, 2)))
		assert_equal( false, container.has_child_at?(Grrr::Point.new(0, 3)) )
	end

	test "it should be possible to retrieve all enabled and disabled child views covering a specific point" do
		container = Grrr::ContainerView.new_detached(4, 4)
		view1 = Grrr::View.new(container, Grrr::Point.new(1, 1), 2, 2)
		view2 = Grrr::View.new_disabled(container, Grrr::Point.new(2, 2), 2, 2)

		assert_equal( [ view1 ], container.get_children_at(Grrr::Point.new(1, 1)) )
		assert_equal( [ view1, view2 ], container.get_children_at(Grrr::Point.new(2, 2)) )
		assert_equal( [], container.get_children_at(Grrr::Point.new(0, 1)) )
	end

	test "it should be possible to determine if any enabled child views cover a specific point" do
		container = Grrr::ContainerView.new_detached(4, 4)
		Grrr::View.new(container, Grrr::Point.new(1, 1), 2, 2)
		Grrr::View.new_disabled(container, Grrr::Point.new(2, 2), 2, 2)

		assert(container.has_any_enabled_child_at?(Grrr::Point.new(2, 2)))
		assert_equal( false, container.has_any_enabled_child_at?(Grrr::Point.new(3, 3)) )
		assert_equal( false, container.has_any_enabled_child_at?(Grrr::Point.new(0, 3)) )
	end

	test "it should be possible to retrieve the topmost enabled child view covering a specific point" do
		container = Grrr::ContainerView.new_detached(4, 4)
		view1 = Grrr::View.new(container, Grrr::Point.new(1, 1), 2, 2)
		Grrr::View.new_disabled(container, Grrr::Point.new(2, 2), 2, 2)

		assert_equal( view1, container.get_topmost_enabled_child_at(Grrr::Point.new(2, 2)) )
		assert_equal( nil, container.get_topmost_enabled_child_at(Grrr::Point.new(0, 1)) )
	end

	test "when an enabled child view is added to a container that has buttons pressed on child views bounds the buttons should be released on the container before the child view is added" do
		container = Grrr::ContainerView.new_detached(4, 4)
		container.press(Grrr::Point.new(0, 0))
		container.press(Grrr::Point.new(1, 1))
		container.press(Grrr::Point.new(2, 2))
		container.press(Grrr::Point.new(3, 3))

		Grrr::View.new(container, Grrr::Point.new(1, 1), 2, 2)

		assert(container.is_pressed_at?(Grrr::Point.new(0, 0)))
		assert(container.is_released_at?(Grrr::Point.new(1, 1)))
		assert(container.is_released_at?(Grrr::Point.new(2, 2)))
		assert(container.is_pressed_at?(Grrr::Point.new(3, 3)))
	end

	test "it should be possible to retrieve all parents of a child view" do
		container1 = Grrr::ContainerView.new_detached(4, 4)
		container2 = Grrr::ContainerView.new(container1, Grrr::Point.new(0,0), 4, 4)
		container3 = Grrr::ContainerView.new(container2, Grrr::Point.new(0,0), 4, 4)
		view = Grrr::View.new(container3, Grrr::Point.new(0,0), 4, 4)

		assert_equal(
			[container3, container2, container1],
			view.get_parents
		)
	end

	test "it should not be possible to add a view as a child to a container if the view already has a parent" do
		container1 = Grrr::ContainerView.new_detached(4, 4)
		container2 = Grrr::ContainerView.new_detached(4, 4)
		view = Grrr::View.new(container1, Grrr::Point.new(0, 0), 2, 2)
		assert_raise(RuntimeError) { container2.add_child(view, Grrr::Point.new(0, 0)) }
	end

	test "it should not be possible to add a child view at a negative origin" do
		container = Grrr::ContainerView.new_detached(4, 4)
		view = Grrr::View.new_detached(2, 2)
		assert_raise(RuntimeError) { container.add_child(view, Grrr::Point.new(-1, 1)) }
		assert_raise(RuntimeError) { container.add_child(view, Grrr::Point.new(1, -1)) }
		assert_raise(RuntimeError) { container.add_child(view, Grrr::Point.new(-1, -1)) }
	end

	test "when a child view is enabled on a container that have buttons pressed on the child views bounds the buttons should be released on the container before the child view is enabled" do
		container = Grrr::ContainerView.new_detached(4, 4)
		view = Grrr::View.new_disabled(container, Grrr::Point.new(1, 1), 2, 2)
		container.press(Grrr::Point.new(0, 0))
		container.press(Grrr::Point.new(1, 1))
		container.press(Grrr::Point.new(2, 2))
		container.press(Grrr::Point.new(3, 3))

		view.enable

		assert(container.is_pressed_at?(Grrr::Point.new(0, 0)))
		assert(container.is_released_at?(Grrr::Point.new(1, 1)))
		assert(container.is_released_at?(Grrr::Point.new(2, 2)))
		assert(container.is_pressed_at?(Grrr::Point.new(3, 3)))
	end

	# button events and state
	test "a containers incoming button events should be forwarded to any enabled child view that cover the affected button" do
		top_container = Grrr::ContainerView.new_detached(4, 4)
		child_container = Grrr::ContainerView.new(top_container, Grrr::Point.new(1, 1), 3, 3)
		view = Grrr::ContainerView.new(child_container, Grrr::Point.new(1, 1), 2, 2)

		assert_equal(
			[
				{:view => view, :point => Grrr::Point.new(0, 0)}
			],
			top_container.press(Grrr::Point.new(2, 2))
		)
		assert(view.is_pressed_at?(Grrr::Point.new(0, 0)))
	end

	test "a containers incoming button events should not be forwarded to any disabled child views that cover the affected button" do
		container = Grrr::ContainerView.new_detached(4, 4)
		view = Grrr::View.new(container, Grrr::Point.new(0,0), 4, 4)

		view.disable

		assert_equal(
			[
				{:view => container, :point => Grrr::Point.new(0, 0)}
			],
			container.press(Grrr::Point.new(0, 0))
		)
	end

	test "when incoming button events are forwarded by non press through containers they should not be handled on the container" do
		top_container = Grrr::ContainerView.new_detached(4, 4, true, false)
		child_container = Grrr::ContainerView.new(top_container, Grrr::Point.new(1, 1), 3, 3, true, false)
		view = Grrr::ContainerView.new(child_container, Grrr::Point.new(1, 1), 2, 2)

		assert_equal(
			[
				{:view => view, :point => Grrr::Point.new(0, 0)}
			],
			top_container.press(Grrr::Point.new(2, 2))
		)
		assert(top_container.is_released_at?(Grrr::Point.new(2, 2)))
		assert(child_container.is_released_at?(Grrr::Point.new(1, 1)))
		assert(view.is_pressed_at?(Grrr::Point.new(0, 0)))
	end

	test "when incoming button events are forwarded by press through containers they should also be handled on the container" do
		top_container = Grrr::ContainerView.new_detached(8, 8, true, true)
		child_container = Grrr::ContainerView.new(top_container, Grrr::Point.new(1, 1), 3, 3, true, true)
		view = Grrr::View.new(child_container, Grrr::Point.new(1, 1), 2, 2)

		assert_equal(
			[
				{:view => view, :point => Grrr::Point.new(0, 0)},
				{:view => child_container, :point => Grrr::Point.new(1, 1)},
				{:view => top_container, :point => Grrr::Point.new(2, 2)}
			],
			top_container.press(Grrr::Point.new(2, 2))
		)
		assert(top_container.is_pressed_at?(Grrr::Point.new(2, 2)))
		assert(child_container.is_pressed_at?(Grrr::Point.new(1, 1)))
		assert(view.is_pressed_at?(Grrr::Point.new(0, 0)))
	end

	test "when a non press through container view is disabled all its pressed buttons and all its enabled childrens pressed buttons should be released" do
		top_container = Grrr::ContainerView.new_detached(8, 8)
		child_container = Grrr::ContainerView.new(top_container, Grrr::Point.new(0, 0), 8, 8)
		view1 = Grrr::View.new(child_container, Grrr::Point.new(0, 0), 2, 2)
		view2 = Grrr::View.new(child_container, Grrr::Point.new(2, 2), 2, 2)
		top_container.to_points.each { |point| top_container.press(point) }

		top_container.disable

		assert(top_container.all_released?)
		assert(child_container.all_released?)
		assert(view1.all_released?)
		assert(view2.all_released?)
	end

	test "when a press through container view is disabled all its pressed buttons and all its enabled childrens pressed buttons should be released" do
		top_container = Grrr::ContainerView.new_detached(8, 8, true, true)
		child_container = Grrr::ContainerView.new(top_container, Grrr::Point.new(0, 0), 8, 8, true, true)
		view1 = Grrr::View.new(child_container, Grrr::Point.new(0, 0), 2, 2)
		view2 = Grrr::View.new(child_container, Grrr::Point.new(2, 2), 2, 2)
		top_container.to_points.each { |point| top_container.press(point) }

		top_container.disable

		assert(top_container.all_released?)
		assert(child_container.all_released?)
		assert(view1.all_released?)
		assert(view2.all_released?)
	end

	# led events and refresh
	test "if a point of a container is refreshed and an enabled child view cover the point the child view led state should override container led state" do
		top_container = MockLitContainerView.new_detached(4, 4)
		top_container.id = :top_container
		child_container = Grrr::ContainerView.new(top_container, Grrr::Point.new(1, 1), 3, 3)
		child_container.id = :child_container
		view = MockLitView.new(child_container, Grrr::Point.new(1, 1), 2, 2)
		view.id = :view
		view_led_refreshed_listener = MockViewLedRefreshedListener.new(top_container)

		top_container.refresh_point(Grrr::Point.new(0, 0))

		assert(
			view_led_refreshed_listener.has_been_notified_of?(
				[
					{ :source => :top_container, :point => Grrr::Point.new(0, 0), :on => true }
				]
			)
		)

		top_container.refresh_point(Grrr::Point.new(1, 1))

		assert(
			view_led_refreshed_listener.has_been_notified_of?(
				[
					{ :source => :top_container, :point => Grrr::Point.new(0, 0), :on => true },
					{ :source => :child_container, :point => Grrr::Point.new(1, 1), :on => false }
				]
			)
		)

		top_container.refresh_point(Grrr::Point.new(2, 2))

		assert(
			view_led_refreshed_listener.has_been_notified_of?(
				[
					{ :source => :top_container, :point => Grrr::Point.new(0, 0), :on => true },
					{ :source => :child_container, :point => Grrr::Point.new(1, 1), :on => false },
					{ :source => :view, :point => Grrr::Point.new(2, 2), :on => true }
				]
			)
		)
	end

	test "when an area of a container is refreshed on the points where enabled child views are the child view led state should override container led state" do
		top_container = MockLitContainerView.new_detached(4, 4)
		top_container.id = :top_container
		child_container = Grrr::ContainerView.new(top_container, Grrr::Point.new(1, 1), 3, 3)
		child_container.id = :child_container
		view = MockLitView.new(child_container, Grrr::Point.new(1, 1), 2, 2)
		view.id = :view
		view_led_refreshed_listener = MockViewLedRefreshedListener.new(top_container)

		top_container.refresh_bounds(Grrr::Point.new(1, 1), 3, 2)

		assert(
			view_led_refreshed_listener.has_been_notified_of?(
				[
					{ :source => :child_container, :point => Grrr::Point.new(1, 1), :on => false },
					{ :source => :child_container, :point => Grrr::Point.new(2, 1), :on => false },
					{ :source => :child_container, :point => Grrr::Point.new(3, 1), :on => false },
					{ :source => :child_container, :point => Grrr::Point.new(1, 2), :on => false },
					{ :source => :view, :point => Grrr::Point.new(2, 2), :on => true },
					{ :source => :view, :point => Grrr::Point.new(3, 2), :on => true },
				]
			)
		)
	end

	test "when an entire container is refreshed on the points where enabled child views are the child view led state should override container led state" do
		top_container = MockLitContainerView.new_detached(4, 4)
		top_container.id = :top_container
		child_container = Grrr::ContainerView.new(top_container, Grrr::Point.new(1, 1), 3, 3)
		child_container.id = :child_container
		view = MockLitView.new(child_container, Grrr::Point.new(1, 1), 2, 2)
		view.id = :view
		view_led_refreshed_listener = MockViewLedRefreshedListener.new(top_container)

		top_container.refresh

		assert(
			view_led_refreshed_listener.has_been_notified_of?(
				[
					{ :source => :top_container, :point => Grrr::Point.new(0, 0), :on => true },
					{ :source => :top_container, :point => Grrr::Point.new(1, 0), :on => true },
					{ :source => :top_container, :point => Grrr::Point.new(2, 0), :on => true },
					{ :source => :top_container, :point => Grrr::Point.new(3, 0), :on => true },
					{ :source => :top_container, :point => Grrr::Point.new(0, 1), :on => true },
					{ :source => :child_container, :point => Grrr::Point.new(1, 1), :on => false },
					{ :source => :child_container, :point => Grrr::Point.new(2, 1), :on => false },
					{ :source => :child_container, :point => Grrr::Point.new(3, 1), :on => false },
					{ :source => :top_container, :point => Grrr::Point.new(0, 2), :on => true },
					{ :source => :child_container, :point => Grrr::Point.new(1, 2), :on => false },
					{ :source => :view, :point => Grrr::Point.new(2, 2), :on => true },
					{ :source => :view, :point => Grrr::Point.new(3, 2), :on => true },
					{ :source => :top_container, :point => Grrr::Point.new(0, 3), :on => true },
					{ :source => :child_container, :point => Grrr::Point.new(1, 3), :on => false },
					{ :source => :view, :point => Grrr::Point.new(2, 3), :on => true },
					{ :source => :view, :point => Grrr::Point.new(3, 3), :on => true }
				]
			)
		)
	end

	test "when an enabled view that has a parent is refreshed led state should automatically be forwarded to the parent" do
		top_container = MockLitContainerView.new_detached(4, 4)
		top_container.id = :top_container
		child_container = Grrr::ContainerView.new(top_container, Grrr::Point.new(1, 1), 3, 3)
		child_container.id = :child_container
		view = MockLitView.new(child_container, Grrr::Point.new(1, 1), 2, 2)
		view.id = :view
		view_led_refreshed_listener = MockViewLedRefreshedListener.new(top_container)

		view.refresh

		assert(
			view_led_refreshed_listener.has_been_notified_of?(
				[
					{ :source => :view, :point => Grrr::Point.new(2, 2), :on => true },
					{ :source => :view, :point => Grrr::Point.new(3, 2), :on => true },
					{ :source => :view, :point => Grrr::Point.new(2, 3), :on => true },
					{ :source => :view, :point => Grrr::Point.new(3, 3), :on => true }
				]
			)
		)
	end

	test "when an enabled view that has a disabled parent is refreshed led state should not be forwarded to the parent" do
		container = Grrr::ContainerView.new_detached(4, 4)
		view = Grrr::View.new(container, Grrr::Point.new(0,0), 4, 4)
		container.disable

		view_led_refreshed_listener = MockViewLedRefreshedListener.new(container)

		view.refresh_point(Grrr::Point.new(0, 0))
		view.refresh_bounds(Grrr::Point.new(1, 1), 1, 1)
		view.refresh

		assert(view_led_refreshed_listener.has_not_been_notified_of_anything?)
	end

	test "it should be possible to refresh only the points of a container where led state is not overridden by any child view" do
		top_container = MockLitContainerView.new_detached(4, 4)
		top_container.id = :top_container
		child_container = Grrr::ContainerView.new(top_container, Grrr::Point.new(1, 1), 3, 3)
		child_container.id = :child_container
		view = MockLitView.new(child_container, Grrr::Point.new(1, 1), 2, 2)
		view.id = :view
		view_led_refreshed_listener = MockViewLedRefreshedListener.new(top_container)

		top_container.refresh(false)

		assert(
			view_led_refreshed_listener.has_been_notified_of?(
				[
					{ :source => :top_container, :point => Grrr::Point.new(0, 0), :on => true },
					{ :source => :top_container, :point => Grrr::Point.new(1, 0), :on => true },
					{ :source => :top_container, :point => Grrr::Point.new(2, 0), :on => true },
					{ :source => :top_container, :point => Grrr::Point.new(3, 0), :on => true },
					{ :source => :top_container, :point => Grrr::Point.new(0, 1), :on => true },
					{ :source => :top_container, :point => Grrr::Point.new(0, 2), :on => true },
					{ :source => :top_container, :point => Grrr::Point.new(0, 3), :on => true }
				]
			)
		)
	end

	test "when a child view is added it should automatically be refreshed" do
		container = Grrr::ContainerView.new_detached(4, 4)
		container.id = :container
		view = Grrr::View.new_detached(2, 2)
		view.id = :view

		view_led_refreshed_listener = MockViewLedRefreshedListener.new(container)

		container.add_child(view, Grrr::Point.new(1, 1))

		assert(
			view_led_refreshed_listener.has_been_notified_of?(
				[
					{ :source => :view, :point => Grrr::Point.new(1, 1), :on => false },
					{ :source => :view, :point => Grrr::Point.new(2, 1), :on => false },
					{ :source => :view, :point => Grrr::Point.new(1, 2), :on => false },
					{ :source => :view, :point => Grrr::Point.new(2, 2), :on => false }
				]
			)
		)
	end

	test "when a child view is disabled its bounds on parent should automatically be refreshed" do
		container = Grrr::ContainerView.new_detached(4, 4)
		container.id = :container
		view = Grrr::View.new(container, Grrr::Point.new(1, 1), 2, 2)
		view.id = :view

		view_led_refreshed_listener = MockViewLedRefreshedListener.new(container)

		view.disable

		assert(
			view_led_refreshed_listener.has_been_notified_of?(
				[
					{ :source => :container, :point => Grrr::Point.new(1, 1), :on => false },
					{ :source => :container, :point => Grrr::Point.new(2, 1), :on => false },
					{ :source => :container, :point => Grrr::Point.new(1, 2), :on => false },
					{ :source => :container, :point => Grrr::Point.new(2, 2), :on => false }
				]
			)
		)
	end

	test "when an enabled child view is removed its bounds on parent should automatically be refreshed" do
		container = Grrr::ContainerView.new_detached(4, 4)
		container.id = :container
		view = Grrr::View.new(container, Grrr::Point.new(1, 1), 2, 2)
		view.id = :view

		view_led_refreshed_listener = MockViewLedRefreshedListener.new(container)

		container.remove_child(view)

		assert(
			view_led_refreshed_listener.has_been_notified_of?(
				[
					{ :source => :container, :point => Grrr::Point.new(1, 1), :on => false },
					{ :source => :container, :point => Grrr::Point.new(2, 1), :on => false },
					{ :source => :container, :point => Grrr::Point.new(1, 2), :on => false },
					{ :source => :container, :point => Grrr::Point.new(2, 2), :on => false }
				]
			)
		)
	end

	test "when a disabled child view is removed its bounds on parent should not be refreshed" do
		container = Grrr::ContainerView.new_detached(4, 4)
		container.id = :container
		view = Grrr::View.new_disabled(container, Grrr::Point.new(1, 1), 2, 2)
		view.id = :view

		view_led_refreshed_listener = MockViewLedRefreshedListener.new(container)

		container.remove_child(view)

		assert(view_led_refreshed_listener.has_not_been_notified_of_anything?)
	end

	# string representations
	test "the string representation of a container view should include id bounds and whether the view is enabled" do
		container = Grrr::ContainerView.new_detached(4, 3)
		assert_equal(
			"a Grrr::ContainerView (4x3, enabled)",
			container.to_s
		)
		container.id = :test
		assert_equal(
			"a Grrr::ContainerView (test, 4x3, enabled)",
			container.to_s
		)
	end

	test "plot should indicate enabled children of a view and where the view currently is pressed and lit" do
		container = MockOddColsLitContainerView.new_detached(4, 3)
		view = Grrr::View.new(container, Grrr::Point.new(1, 1), 2, 2)
		assert_equal(
			"   0   1   2   3        0   1   2   3 \n" +
			"0  -   -   -   -     0  -   L   -   L \n" +
			"1  -  [-] [-]  -     1  -  [-] [-]  L \n" +
			"2  -  [-] [-]  -     2  -  [-] [-]  L \n",
			container.to_plot
		)
		container.press(Grrr::Point.new(0, 0))
		view.press(Grrr::Point.new(0, 1))
		assert_equal(
			"   0   1   2   3        0   1   2   3 \n" +
			"0  P   -   -   -     0  -   L   -   L \n" +
			"1  -  [-] [-]  -     1  -  [-] [-]  L \n" +
			"2  -  [-] [-]  -     2  -  [-] [-]  L \n",
			container.to_plot
		)
		view.disable
		assert_equal(
			"   0   1   2   3        0   1   2   3 \n" +
			"0  P   -   -   -     0  -   L   -   L \n" +
			"1  -   -   -   -     1  -   L   -   L \n" +
			"2  -   -   -   -     2  -   L   -   L \n",
			container.to_plot
		)
	end

	test "a tree plot of a view should indicate where buttons and leds are currently pressed and lit and also include its string representation and also recursively print its childrens tree plots" do
		top_container = Grrr::ContainerView.new_detached(4, 3)
		container2 = Grrr::ContainerView.new(top_container, Grrr::Point.new(2, 1), 2, 2)
		Grrr::View.new(container2, Grrr::Point.new(0, 0), 2, 1)
		Grrr::View.new(top_container, Grrr::Point.new(0, 0), 2, 1)
		assert_equal(
			"a Grrr::ContainerView (4x3, enabled)\n" +
			"   0   1   2   3        0   1   2   3 \n" +
			"0 [-] [-]  -   -     0 [-] [-]  -   - \n" +
			"1  -   -  [-] [-]    1  -   -  [-] [-]\n" +
			"2  -   -  [-] [-]    2  -   -  [-] [-]\n" +
			"\n" +
			"\ta Grrr::ContainerView (2x2, enabled)\n" +
			"\t   0   1        0   1 \n" +
			"\t0 [-] [-]    0 [-] [-]\n" +
			"\t1  -   -     1  -   - \n" +
			"\n" +
			"\t\ta Grrr::View (2x1, enabled)\n" +
			"\t\t  0 1      0 1\n" +
			"\t\t0 - -    0 - -\n" +
			"\n" +
			"\ta Grrr::View (2x1, enabled)\n" +
			"\t  0 1      0 1\n" +
			"\t0 - -    0 - -\n" +
			"\n",
			top_container.to_tree(true)
		)
	end
end
