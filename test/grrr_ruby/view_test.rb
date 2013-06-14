include Grrr

class TestView < Test::Unit::TestCase
	def setup
		save_globals
		disable_trace_and_flash
		@a_detached_4x4_view = View.new(nil, nil, 4, 4)
		@a_detached_4x4_view.id = :a_detached_4x4_view
	end

	def teardown
		restore_globals
	end

	test "it should be possible to send button events with a point defined in a string to a view and get a response of how the event was handled" do
		view = @a_detached_4x4_view

		response = view.press "0@0"

		assert_equal(
			[
				{:view => view, :point => Point.new(0, 0)}
			],
			response
		)

		response = view.release "0@0"

		assert_equal(
			[
				{:view => view, :point => Point.new(0, 0)}
			],
			response
		)
	end
end
