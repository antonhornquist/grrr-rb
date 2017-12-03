require 'enumerator'

class Grrr::View
	DEFAULT_NUM_COLS = 4
	DEFAULT_NUM_ROWS = 4
	DEFAULT_INDICATE_REPEAT = 2
	DEFAULT_INDICATE_INTERVAL = 50
	DEFAULT_FLASH_DELAY = 75

	attr_reader :parent
	attr_reader :origin
	attr_reader :num_cols
	attr_reader :num_rows
	attr_accessor :id
	attr_reader :view_led_refreshed_action
	attr_accessor :action

	def initialize(parent=nil, origin=nil, num_cols=nil, num_rows=nil, enabled=true)
		@parent = nil
		@id = nil
		@view_led_refreshed_action = nil
		@action = nil
		@is_lit_at_func = nil
		@value = nil
		@view_button_state_changed_action = nil
		@parent_view_led_refreshed_listener = nil
		@view_was_enabled_action = nil
		@view_was_disabled_action = nil

		@num_cols = num_cols ? num_cols : DEFAULT_NUM_COLS
		@num_rows = num_rows ? num_rows : (num_cols ? num_cols : DEFAULT_NUM_ROWS)
		raise "minimum size is 1x1" if @num_cols < 1 or @num_rows < 1

		@enabled = enabled

		@points_pressed = Array.new
		@inverted_leds_map = Array.fill2d(@num_cols, @num_rows) { false }
		@inverted_leds_mutex = Mutex.new

		validate_parent_origin_and_add_to_parent(parent, origin)
	end

	def self.new_detached(num_cols=nil, num_rows=nil, enabled=true)
		new(nil, nil, num_cols, num_rows, enabled)
	end

	def self.new_disabled(parent=nil, origin=nil, num_cols=nil, num_rows=nil)
		new(parent, origin, num_cols, num_rows, false)
	end

	# Bounds

	def origin=(origin)
		raise "not yet implemented"
	end

	def num_view_buttons
		@num_cols * @num_rows
	end

	def to_points
		to_points_from(Grrr::Point.new(0, 0))
	end

	def to_points_from_origin
		to_points_from(@origin)
	end

	def to_points_from(origin)
		self.class.bounds_to_points(origin, @num_cols, @num_rows)
	end

	def self.bounds_to_points(origin, num_cols, num_rows)
		Array.fill(num_cols * num_rows) { |i| Grrr::Point.new(origin.x+(i % num_cols), origin.y+(i / num_cols)) }
	end

	def self.points_sect(points1, points2)
		points1.select do |point1|
			points2.detect do |point2|
				point1 == point2
			end
		end
	end

	def self.bounds_contain_point?(origin, num_cols, num_rows, point)
		origin.x <= point.x and origin.y <= point.y and point.x < origin.x + num_cols and point.y < origin.y + num_rows
	end

	def left_top_point
		Grrr::Point.new(leftmost_col, topmost_row)
	end

	def right_top_point
		Grrr::Point.new(rightmost_col, topmost_row)
	end

	def left_bottom_point
		Grrr::Point.new(leftmost_col, bottommost_row)
	end

	def right_bottom_point
		Grrr::Point.new(rightmost_col, bottommost_row)
	end

	def leftmost_col
		0
	end

	def rightmost_col
		@num_cols-1
	end

	def topmost_row
		0
	end

	def bottommost_row
		@num_rows-1
	end

	# Validations

	def validate_contains_point(point)
		raise "point #{point} not within bounds of [#{self}]" if not contains_point? point
	end

	def contains_point?(point)
		(0...@num_cols).include? point.x and (0...@num_rows).include? point.y
	end

	def validate_contains_bounds(origin, num_cols, num_rows)
		raise "bounds (origin: #{origin}, num_cols: #{num_cols}, num_rows: #{num_rows}) not within bounds of [#{self}]" if not contains_bounds?(origin, num_cols, num_rows)
	end

	def contains_bounds?(origin, num_cols, num_rows)
		0 <= origin.x and 0 <= origin.y and origin.x + num_cols <= @num_cols and origin.y + num_rows <= @num_rows
	end

	# Button Events and State

	def press(point)
		handle_view_button_event(self, point.to_point, true)
	end

	def release(point)
		handle_view_button_event(self, point.to_point, false)
	end

	def release_all
		release_all_within_bounds(Grrr::Point.new(0, 0), @num_cols, @num_rows)
	end

	def release_all_within_bounds(origin, num_cols, num_rows)
		points_pressed_within_bounds(origin, num_cols, num_rows).each { |point| release(point) }
	end

	def is_pressed_at?(point)
		validate_contains_point(point)
		# Ruby does equality match in Array#include?.
		# SuperCollider matches identical objects in ArrayedCollection.includes.
		@points_pressed.include?(point)
	end

	def is_released_at?(point)
		not is_pressed_at?(point)
	end

	def is_pressed_at_skip_validation?(point)
		# Ruby does equality match in Array#include?.
		# SuperCollider matches identical objects in ArrayedCollection.includes.
		@points_pressed.include?(point)
	end

	def any_pressed?
		not @points_pressed.empty?
	end

	def any_pressed_within_bounds?(origin, num_cols, num_rows)
		not points_pressed_within_bounds(origin, num_cols, num_rows).empty?
	end

	def any_released?
		@points_pressed.size != num_view_buttons
	end

	def any_released_within_bounds?(origin, num_cols, num_rows)
		points_pressed_within_bounds(origin, num_cols, num_rows).size != num_cols*num_rows
	end

	def all_pressed?
		@points_pressed.size == num_view_buttons
	end

	def all_pressed_within_bounds?(origin, num_cols, num_rows)
		points_pressed_within_bounds(origin, num_cols, num_rows).size == num_cols*num_rows
	end

	def all_released?
		@points_pressed.empty?
	end

	def all_released_within_bounds?(origin, num_cols, num_rows)
		points_pressed_within_bounds(origin, num_cols, num_rows).empty?
	end

	def num_pressed
		@points_pressed.size
	end

	def num_pressed_within_bounds(origin, num_cols, num_rows)
		points_pressed_within_bounds(origin, num_cols, num_rows).size
	end

	def num_released
		num_view_buttons-num_pressed
	end

	def num_released_within_bounds(origin, num_cols, num_rows)
		num_cols*num_rows - points_pressed_within_bounds(origin, num_cols, num_rows).size
	end

	def first_pressed
		@points_pressed.first
	end

	def last_pressed
		@points_pressed.last
	end

	def leftmost_col_pressed
		points = leftmost_pressed
		points.empty? ? nil : points.first.x
	end

	def rightmost_col_pressed
		points = rightmost_pressed
		points.empty? ? nil : points.first.x
	end

	def topmost_row_pressed
		points = topmost_pressed
		points.empty? ? nil : points.first.y
	end

	def bottommost_row_pressed
		points = bottommost_pressed
		points.empty? ? nil : points.first.y
	end

	def leftmost_pressed
		min_x = @points_pressed.collect { |point| point.x }.min
		@points_pressed.select { |point| point.x == min_x }
	end

	def rightmost_pressed
		max_x = @points_pressed.collect { |point| point.x }.max
		@points_pressed.select { |point| point.x == max_x }
	end

	def topmost_pressed
		min_y = @points_pressed.collect { |point| point.y }.min
		@points_pressed.select { |point| point.y == min_y }
	end

	def bottommost_pressed
		max_y = @points_pressed.collect { |point| point.y }.max
		@points_pressed.select { |point| point.y == max_y }
	end

	def handle_view_button_event(source, point, pressed)
		if @enabled
			validate_contains_point(point)
			if is_pressed_at_skip_validation?(point) != pressed
				if pressed
					@points_pressed << point
				else
					@points_pressed.delete(point)
				end
				@view_button_state_changed_action.call(point, pressed) if @view_button_state_changed_action

				if Grrr::Common.trace_button_events
					puts(
						"in %s - button %s at %s (source: [%s]) handled in [%s]" %
						[
							"Method " + self.class.to_s + "#handle_view_button_event",
							pressed ? 'press' : 'release',
							point.to_s,
							source.to_s,
							self.to_s,
						]
					)
				end

				[{:view => self, :point => point}]
			else
				if Grrr::Common.trace_button_events
					puts(
						"in %s - button state is already %s in [%s] at %s %s" %
						[
							"Method " + self.class.to_s + "#handle_view_button_event",
							pressed ? 'pressed' : 'released',
							self.to_s,
							point.to_s,
							@view_button_state_changed_action ? ' - view_button_state_changed_action not invoked' : ''
						]
					)
				end

				[]
			end
		else
			[]
		end
	end

	def points_pressed
		@points_pressed.dup
	end

	def points_pressed_within_bounds(origin, num_cols, num_rows)
		@points_pressed.select { |point| self.class.bounds_contain_point?(origin, num_cols, num_rows, point) }
	end

	# Leds and Refresh

	def refresh(refresh_children=true)
		if @enabled
			to_points.each { |point| refresh_point(point, refresh_children) }
		else
			raise "view is disabled"
		end
	end

	def refresh_bounds(origin, num_cols, num_rows, refresh_children=true)
		if @enabled
			validate_contains_bounds origin, num_cols, num_rows
			self.class.bounds_to_points(origin, num_cols, num_rows).each { |point| refresh_point(point, refresh_children) }
		else
			raise "view is disabled"
		end
	end

	def refresh_points(points, refresh_children=true)
		if @enabled
			points.each { |point| refresh_point(point) }
		else
			raise "view is disabled"
		end
	end

	def refresh_point(point, refresh_children=true)
		if @enabled
			validate_contains_point(point)
			if has_view_led_refreshed_action?
				@view_led_refreshed_action.call(self, point, is_lit_at?(point))
			end
		else
			raise "view is disabled"
		end
	end

	def is_lit_at?(point)
		validate_contains_point(point)
		if @is_lit_at_func
			@is_lit_at_func.call(point) != @inverted_leds_map[point.x][point.y]
		else
			false
		end
	end

	def is_unlit_at?(point)
		not is_lit_at?(point)
	end

	def any_lit?
		to_points.any? { |point| is_lit_at?(point) }
	end

	def all_lit?
		to_points.all? { |point| is_lit_at?(point) }
	end

	def any_unlit?
		to_points.any? { |point| is_unlit_at?(point) }
	end

	def all_unlit?
		to_points.all? { |point| is_unlit_at?(point) }
	end

	def get_led_state_within_bounds(origin, num_cols, num_rows)
		self.class.bounds_to_points(origin, num_cols, num_rows).collect { |point| [ point,  is_lit_at?(point) ] }
	end

	def pr_disable_led_forwarding_to_parent
		if @parent_view_led_refreshed_listener
			remove_action(@parent_view_led_refreshed_listener, :view_led_refreshed_action);
		end
	end

	def pr_enable_led_forwarding_to_parent
		if @parent_view_led_refreshed_listener
			add_action(@parent_view_led_refreshed_listener, :view_led_refreshed_action);
		end
	end

	def pr_do_then_refresh_changed_leds(&func)
		if has_parent?
			pre = get_led_state_within_bounds(origin_to_use, @num_cols, @num_rows)
			pr_disable_led_forwarding_to_parent
		end

		func.call

		if has_parent?
			pr_enable_led_forwarding_to_parent
			post = get_led_state_within_bounds(origin_to_use, @num_cols, @num_rows)

			points_having_changed_state = post.select do |point_state_1|
				pre.any? do |point_state_2|
					(point_state_1[0] == point_state_2[0]) and (point_state_1[1] == point_state_2[1])
				end
			end

			points_to_refresh = points_having_changed_state.collect { |point_state| point_state[0] }
			refresh_points(points_to_refresh)
		end
	end

	# Indicate support

	def indicate_view(repeat=nil, interval=nil)
		indicate_points(to_points, repeat, interval)
	end

	def indicate_bounds(origin, num_cols, num_rows, repeat=nil, interval=nil)
		indicate_points(self.class.bounds_to_points(origin, num_cols, num_rows), repeat, interval)
	end

	def indicate_point(point, repeat=nil, interval=nil)
		indicate_points([point], repeat, interval)
	end

	def indicate_points(points, repeat=nil, interval=nil)
		interval_in_seconds = (interval ? interval : DEFAULT_INDICATE_INTERVAL) / 1000.0

		Thread.new do
			(repeat ? repeat : DEFAULT_INDICATE_REPEAT).times do
				[true, false].each { |bool|
					if has_view_led_refreshed_action?
						points.each { |point| @view_led_refreshed_action.call(self, point, bool) }
					end
					sleep(interval_in_seconds)
				}
			end
			refresh_points(points) if is_enabled?
		end
	end

	# Flash support

	def flash_view(delay=nil)
		flash_points(to_points, delay)
	end

	def flash_bounds(origin, num_cols, num_rows, delay=nil)
		flash_points(self.class.bounds_to_points(origin, num_cols, num_rows), delay)
	end

	def flash_point(point, delay=nil)
		flash_points([point], delay)
	end

	def flash_points(points, delay=nil)
		pr_set_inverted_leds_map(points, true)
		pr_schedule_to_reset_leds(
			points,
			(delay ? delay : DEFAULT_FLASH_DELAY) / 1000.0
		)
	end

	def pr_set_inverted_leds_map(points, bool)
		@inverted_leds_mutex.synchronize do # ruby specific mutex not needed in SuperCollider due to SuperCollider's cooperative multithreading
			points.each { |point| @inverted_leds_map[point.x][point.y] = bool }
			refresh_points(points) if is_enabled?
		end
	end

	def pr_schedule_to_reset_leds(points, delay_in_seconds)
		Thread.new do
			sleep(delay_in_seconds)
			pr_set_inverted_leds_map(points, false)
		end
	end

	# Enable / Disable View

	def enable
		self.enabled=(true)
	end

	def disable
		self.enabled=(false)
	end

	def is_enabled?
		@enabled
	end

	def is_disabled?
		not @enabled
	end

	def enabled=(bool)
		raise "already #{@enabled ? 'enabled' : 'disabled'}" if @enabled == bool
		if bool
			if has_parent?
				@parent.release_all_within_bounds(@origin, @num_cols, @num_rows)
			end
			@enabled = true
			refresh
			@view_was_enabled_action.call(self) if @view_was_enabled_action
		else
			release_all
			@enabled = false
			if has_parent?
				@parent.refresh_bounds(origin, num_cols, num_rows)
			end
			@view_was_disabled_action.call(self) if @view_was_disabled_action
		end
	end

	# Action and Value

	def add_action(function, selector=:action)
		case selector
		when :view_button_state_changed_action
			@view_button_state_changed_action = @view_button_state_changed_action.add_func(function)
		when :view_led_refreshed_action
			@view_led_refreshed_action = @view_led_refreshed_action.add_func(function)
		when :view_was_enabled_action
			@view_was_enabled_action = @view_was_enabled_action.add_func(function)
		when :view_was_disabled_action
			@view_was_disabled_action = @view_was_disabled_action.add_func(function)
		else
			send(selector.to_setter, send(selector).add_func(function))
		end
	end

	def remove_action(function, selector=:action)
		case selector
		when :view_button_state_changed_action
			@view_button_state_changed_action = @view_button_state_changed_action.remove_proc(function)
		when :view_led_refreshed_action
			@view_led_refreshed_action = @view_led_refreshed_action.remove_proc(function)
		when :view_was_enabled_action
			@view_was_enabled_action = @view_was_enabled_action.remove_proc(function)
		when :view_was_disabled_action
			@view_was_disabled_action = @view_was_disabled_action.remove_proc(function)
		else
			send(selector.to_setter, send(selector).remove_proc(function))
		end
	end

	def value
		@value
	end

	def value=(value)
		if @value != value
			validate_value(value)
			@value = value
			if is_enabled?
				refresh
			end
		end
	end

	def value_action=(value)
		if @value != value
			self.value=(value)
			do_action
		end
	end

	def do_action
		@action.call(self, value) if @action
	end

	def validate_value(value)
		# subclass responsibility
	end

	# Parent - Child

	def validate_parent_origin_and_add_to_parent(parent, origin)
		if parent and origin then
			parent.add_child(self, origin)
		elsif parent
			raise "if a parent is supplied an origin must also be supplied"
		elsif origin
			raise "if an origin is supplied a parent must also be supplied"
		end
	end

	def remove
		if has_parent?
			@parent.remove_child(self)
		else
			raise "[#{self}] has no parent"
		end
	end

	def has_parent?
		if @parent and @origin
			true
		else
			false
		end
	end

	def is_detached?
		not has_parent?
	end

	def has_view_led_refreshed_action?
		@view_led_refreshed_action != nil
	end

	def set_parent_reference(parent, origin)
		raise "cannot set parent reference - [#{self}] already has a parent" if has_parent?

		@parent = parent
		@origin = origin
		@parent_view_led_refreshed_listener = lambda { |source, point, on|
			if @parent.has_view_led_refreshed_action? and @parent.is_enabled? and (@parent.get_topmost_enabled_child_at(origin + point) == self)

				if Grrr::Common.trace_led_events
					puts(
						"led %s at %s (source: [%s]) forwarded to [%s]" %
						[
							on ? 'on' : 'off',
							point.to_s,
							source.to_s,
							@parent.to_s
						]
					)
				end

				@parent.view_led_refreshed_action.call(source, point+@origin, on)
			else

				if Grrr::Common.trace_led_events
					reason = if not @parent.has_view_led_refreshed_action?
						"parent has no view_led_refreshed_action"
					elsif not @parent.is_enabled?
						"parent is disabled"
					elsif @parent.get_topmost_enabled_child_at(origin + point) != self
						"view [%s] is not topmost at point [%s] in parent [%s]" %
						[
							self,
							point.to_s,
							@parent.to_s
						]
					end

					puts(
						"led %s at %s (source: [%s]) not forwarded to [%s] - %s" %
						[
							on ? 'on' : 'off',
							point.to_s,
							source.to_s,
							@parent.to_s,
							reason
						]
					)
				end
			end
		}
		add_action(@parent_view_led_refreshed_listener, :view_led_refreshed_action)
	end

	def remove_parent_reference
		remove_action(@parent_view_led_refreshed_listener, :view_led_refreshed_action)
		@parent = @origin = nil
	end

	def get_parents
		view = self
		parents = Array.new
		while view = view.parent
			parents << view
		end
		parents
	end

	def bring_to_front
		if has_parent?
			@parent.bring_child_to_front(self)
		end
	end

	def send_to_back
		if has_parent?
			@parent.send_child_to_back(self)
		end
	end

	# String representation

	def to_s
		"a %s (%s%dx%d, %s)" % [self.class.to_s, @id ? "#{@id.to_s}, " : "", @num_cols, @num_rows, @enabled ? "enabled" : "disabled"]
	end

	def plot
		puts to_plot
	end

	def plot_tree
		post_tree(true)
	end

	def post_tree(include_details=false, indent_level=0)
		puts to_tree(include_details, indent_level)
	end

	def to_plot(indent_level=0)
		delimiter = "    "
		plot_pressed_lines = Array.fill(@num_rows) { Array.new }
		plot_led_lines = Array.fill(@num_rows) { Array.new }
		to_points.each { |point|
			plot_pressed_lines[point.y] << (is_pressed_at?(point) ? 'P' : '-')
			plot_led_lines[point.y] << (is_lit_at?(point) ? 'L' : '-')
		}
		plot_pressed_lines = plot_pressed_lines.enum_for(:each_with_index).collect { |row, i| i.to_s + ' ' + row.join(' ') }
		plot_led_lines = plot_led_lines.enum_for(:each_with_index).collect { |row, i| i.to_s + ' ' + row.join(' ') }
		plot = '  ' + (0...@num_cols).to_a.join(' ')
		plot = "\t"*indent_level + plot + delimiter + plot + "\n"
		@num_rows.times { |i|
			plot << "\t"*indent_level + plot_pressed_lines[i] + delimiter + plot_led_lines[i] + "\n"
		}
		plot
	end

	def to_tree(include_details=false, indent_level=0)
		"\t"*indent_level + to_s +
		if include_details
			 "\n" + to_plot(indent_level)
		else
			""
		end + "\n"
	end
end
