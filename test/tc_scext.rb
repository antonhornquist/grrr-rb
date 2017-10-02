require 'test/unit'
require 'scext'

=begin
	TODO: sort out scext handling
class TestProcListExtensions < Test::Unit::TestCase
	def setup
		@notifications = Array.new
		@proc1 = lambda { |x| @notifications << (x + 1) }
		@proc2 = lambda { |x| @notifications << (x - 5) }
		@proc3 = lambda { |x| @notifications << (x * 5) }
	end

	test "adding a proc to nil should return a proc" do
		assert_equal(@proc1, nil.add_proc(@proc1))
	end

	test "adding two or more procs to nil should return a proclist" do
		list = nil.add_proc(@proc1, @proc2)
		assert_equal(ProcList, list.class)
		assert_equal(@proc1, list.array[0])
		assert_equal(@proc2, list.array[1])
	end

	test "adding a proc to a proc should return a proclist" do
		list = @proc1.add_proc(@proc2)
		assert_equal(ProcList, list.class)
		assert_equal(@proc1, list.array[0])
		assert_equal(@proc2, list.array[1])
	end

	test "adding a proc to a proclist should return a proclist with the proc added" do
		proclist = ProcList.new(@proc1, @proc2)

		list = proclist.add_proc(@proc3)

		assert_equal(ProcList, list.class)
		assert_equal(@proc1, list.array[0])
		assert_equal(@proc2, list.array[1])
		assert_equal(@proc3, list.array[2])
	end

	test "remove proc should return last proc when only one proc is left" do
		proclist = ProcList.new(@proc1, @proc2)

		ret = proclist.remove_proc(@proc1)

		assert_equal(@proc2, ret)
	end

	test "remove proc should return nil when the last proc was removed" do
		proclist = ProcList.new(@proc1, @proc2)

		proclist.remove_proc(@proc2)
		ret = proclist.remove_proc(@proc1)

		assert_equal(nil, ret)
	end

	test "procs should be evaluated in the order they have in the proclist array" do
		proclist = ProcList.new(@proc1, @proc2, @proc3)

		proclist.call(5)

		assert_equal([6, 0, 25], @notifications)
	end
end
=end

class TestArrayAllTuplesExtension < Test::Unit::TestCase
	test "it should work :)" do
		assert_equal(
			[[1, 2, 3, 4, 5], [10, 20, 30]].all_tuples,
			[ [ 1, 10 ], [ 1, 20 ], [ 1, 30 ], [ 2, 10 ], [ 2, 20 ], [ 2, 30 ], [ 3, 10 ], [ 3, 20 ], [ 3, 30 ], [ 4, 10 ], [ 4, 20 ], [ 4, 30 ], [ 5, 10 ], [ 5, 20 ], [ 5, 30 ] ]
		)

		assert_equal(
			[[1, 2, 3, 4, 5], [10, 20, 30], [5, 6]].all_tuples,
			[ [ 1, 10, 5 ], [ 1, 10, 6 ], [ 1, 20, 5 ], [ 1, 20, 6 ], [ 1, 30, 5 ], [ 1, 30, 6 ], [ 2, 10, 5 ], [ 2, 10, 6 ], [ 2, 20, 5 ], [ 2, 20, 6 ], [ 2, 30, 5 ], [ 2, 30, 6 ], [ 3, 10, 5 ], [ 3, 10, 6 ], [ 3, 20, 5 ], [ 3, 20, 6 ], [ 3, 30, 5 ], [ 3, 30, 6 ], [ 4, 10, 5 ], [ 4, 10, 6 ], [ 4, 20, 5 ], [ 4, 20, 6 ], [ 4, 30, 5 ], [ 4, 30, 6 ], [ 5, 10, 5 ], [ 5, 10, 6 ], [ 5, 20, 5 ], [ 5, 20, 6 ], [ 5, 30, 5 ], [ 5, 30, 6 ] ]
		)
	end
end

=begin
	TODO: sort out scext handling
class TestDependancyExtension < Test::Unit::TestCase
	test "it should be possible to observe changes of a model" do
		model = Object.new
		observer = Object.new

		def observer.update(the_changed, the_changer, arg1, arg2, arg3)
			@notifications = Array.new unless (defined? @notifications)
			@notifications << [the_changed, the_changer, arg1, arg2, arg3]
		end

		def observer.notifications
			@notifications
		end

		model.add_dependant(observer)

		model.changed(:property, :arg1, :arg2, :arg3)

		assert_equal(
			observer.notifications,
			[
				[
					model,
					:property,
					:arg1,
					:arg2,
					:arg3
				]
			]
		)
	end
end
=end

class TestNotificationCenterExtension < Test::Unit::TestCase
	test "it should be possible to register permanent listeners" do
		a = Object.new
		b = Object.new
		c = Object.new

		NotificationCenter.register(a, :test, b, lambda { |*args| puts "hey" })
		NotificationCenter.register(a, :test, c, lambda { |*args| puts "ho" })
	end

	test "it should be possible to register one shot listeners" do
		a = Object.new
		b = Object.new
		c = Object.new

		NotificationCenter.register_one_shot(a, :test, b, lambda { |*args| puts "hey" })
		NotificationCenter.register_one_shot(a, :test, c, lambda { |*args| puts "ho" })
	end

	test "it should be possible to unregister listeners" do
		a = Object.new
		b = Object.new
		c = Object.new
		NotificationCenter.register(a, :test, b, lambda { |*args| puts "hey" })
		NotificationCenter.register(a, :test, c, lambda { |*args| puts "ho" })

		NotificationCenter.unregister(a, :test, b)
		NotificationCenter.unregister(a, :test, c)
	end

	test "it should be possible to clear the NotificationCenter of its listeners" do
		a = Object.new
		b = Object.new
		c = Object.new
		NotificationCenter.register(a, :test, b, lambda { |*args| puts "hey" })
		NotificationCenter.register(a, :test, c, lambda { |*args| puts "ho" })

		NotificationCenter.clear
	end

	test "when a notification is sent the registered actions of all registered listeners observing the object and message should be invoked" do
		arr = Array.new
		a = Object.new
		b = Object.new
		c = Object.new
		NotificationCenter.register(a, :test, b, lambda { |*args| arr << 1 })
		NotificationCenter.register(a, :test, c, lambda { |*args| arr << 2 })

		NotificationCenter.notify(a, :test)

		assert(arr.include?(1))
		assert(arr.include?(2))
	end

	test "when notifications are sent one shot listeners should automatically become unregistered after their action has been invoked" do
		arr = Array.new
		a = Object.new
		b = Object.new
		NotificationCenter.register_one_shot(a, :test, b, lambda { |*args| arr << 1 })

		NotificationCenter.notify(a, :test)
		NotificationCenter.notify(a, :test)

		assert_equal(
			[1],
			arr
		)
	end
end
