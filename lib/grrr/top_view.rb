class Grrr::TopView < Grrr::ContainerView
	def initialize(num_cols=nil, num_rows=nil, enabled=true)
		super(nil, nil, num_cols, num_rows, enabled, true)

		@points_pressed_by_source = Array.fill2d(@num_cols, @num_rows) { Array.new }
	end

	def self.new_detached(num_cols=nil, num_rows=nil, enabled=true) # same as new, this is just to override superclass version
		new(num_cols, num_rows, enabled)
	end

	def self.new_disabled(num_cols=nil, num_rows=nil)
		new(num_cols, num_rows, false)
	end

	# Parent - Child

	def set_parent_reference(parent, origin)
		raise "a #{self.class} may not be added as a child to another view"
	end

	# Button events and state

	def is_pressed_by_source_at?(source, point)
		@points_pressed_by_source[point.x][point.y].include?(source)
	end

	def is_released_by_source_at?(source, point)
		not is_pressed_by_source_at?(source, point)
	end

	def is_pressed_by_one_source_at?(point)
		@points_pressed_by_source[point.x][point.y].size == 1
	end

	def is_not_pressed_by_any_source_at?(point)
		@points_pressed_by_source[point.x][point.y].empty?
	end

	def press(point)
		raise "not available in #{self.class}"
	end

	def release(point)
		raise "not available in #{self.class}"
	end

	def handle_view_button_event(source, point, pressed)
		if @enabled

			if Grrr::Common.trace_button_events
				puts(
					"in %s - button %s at %s (source: [%s]) received." %
					[
						"Method " + self.class.to_s + "#handle_view_button_event",
						pressed ? 'press' : 'release',
						point.to_s,
						source.to_s,
					]
				)
			end

			if pressed
				if is_released_by_source_at?(source, point)

					@points_pressed_by_source[point.x][point.y] << source

					if Grrr::Common.trace_button_events
						puts(
							"in %s - source [%s] not referenced in array - reference was added." %
							[
								"Method " + self.class.to_s + "#handle_view_button_event",
 								source.to_s
							]
						)
					end

					super(source, point, true) if is_pressed_by_one_source_at?(point)
				end
			else
				if is_pressed_by_source_at?(source, point)
					@points_pressed_by_source[point.x][point.y].delete(source)

					if Grrr::Common.trace_button_events
						puts(
							"in %s - source [%s] referenced in array - reference was removed." %
							[
								"Method " + self.class.to_s + "#handle_view_button_event",
 								source.to_s
							]
						)
					end

					super(source, point, false) if is_not_pressed_by_any_source_at?(point)
				end
			end
		end
	end
end
