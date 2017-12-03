class Grrr::MultiButtonView < Grrr::View
	attr_accessor :button_pressed_action
	attr_accessor :button_released_action
	attr_accessor :button_value_changed_action
	attr_reader :num_button_cols
	attr_reader :num_button_rows
	attr_reader :behavior

	def initialize(parent, origin, num_cols=nil, num_rows=nil, enabled=true, coupled=true, behavior=:toggle)
		super(nil, nil, num_cols, num_rows, enabled)

		@button_pressed_action = nil
		@button_value_changed_action = nil

		@coupled = coupled
		@behavior = behavior

		@num_button_cols = @num_cols
		@num_button_rows = @num_rows

		@container_view = Grrr::ContainerView.new_detached(@num_cols, @num_rows)
		@container_view.add_action(lambda { |originating_button, point, on|
			if has_view_led_refreshed_action?
				view_led_refreshed_action.call(self, point, on)
			end
		}, :view_led_refreshed_action)
		add_action(lambda { |point, pressed|
			@container_view.handle_view_button_event(self, point, pressed)
		}, :view_button_state_changed_action)

		pr_reconstruct_children

		# view has to be added to parent after class-specific properties
		# have been initialized, otherwise it is not properly refreshed
		validate_parent_origin_and_add_to_parent(parent, origin)
	end

	def self.new_detached(num_cols=nil, num_rows=nil, enabled=true, coupled=true, behavior=:toggle)
		new(nil, nil, num_cols, num_rows, enabled, coupled, behavior)
	end

	def self.new_decoupled(parent, origin, num_cols=nil, num_rows=nil, enabled=true, behavior=:toggle)
		new(parent, origin, num_cols, num_rows, enabled, false, behavior)
	end

	def is_coupled?
		@coupled
	end

	def coupled=(coupled)
		pr_buttons_do { |button, x, y| button.coupled = coupled }
		@coupled = coupled
	end

	def behavior=(behavior)
		pr_buttons_do { |button, x, y| button.behavior = behavior }
		@behavior = behavior
	end

	def button_is_pressed?(x, y)
		@buttons[x][y].is_pressed?
	end

	def button_is_released?(x, y)
		@buttons[x][y].is_released?
	end

	def clear
		self.value=(Array.fill2d(@num_button_cols, @num_button_rows) { false })
	end

	def clear_action
		self.value_action=(Array.fill2d(@num_button_cols, @num_button_rows) { false })
	end

	def fill
		self.value=(Array.fill2d(@num_button_cols, @num_button_rows) { true })
	end

	def fill_action
		self.value_action=(Array.fill2d(@num_button_cols, @num_button_rows) { true })
	end

	def value
		@buttons.collect { |row| row.collect { |button| button.value } }
	end

	def value=(val)
		validate_value(val)
		pr_buttons_do do |button, x, y|
			button.value = val[x][y]
		end
	end

	def value_action=(val)
		validate_value(val)
		num_button_values_changed = 0
		pr_buttons_do do |button, x, y|
			new_button_value = val[x][y]
			if button_value(x, y) != new_button_value
				set_button_value(x, y, new_button_value)
				@button_value_changed_action.call(self, x, y, new_button_value) if @button_value_changed_action
				num_button_values_changed = num_button_values_changed + 1
			end
		end
		if num_button_values_changed > 0
			do_action
		end
	end

	def validate_value(val)
		if not(val.size == @num_button_cols and val.all? { |row| row.size == @num_button_rows })
			raise "value must be a 2-dimensional array of #{@num_button_cols}x#{@num_button_rows} values"
		end
		pr_buttons_do do |button, x, y|
			button.validate_value(val[x][y])
		end
	end

	def buttons_pressed
		@buttons.collect do |row, x|
			row.collect do |button, y|
				[button, Grrr::Point.new(x, y)]
			end
		end.flatten.select do |button_and_pos|
			button_and_pos[0].is_pressed?
		end.collect do |button_and_pos|
			button_and_pos[1]
		end
	end

	def button_value(x, y)
		@buttons[x][y].value
	end

	def set_button_value(x, y, val)
		@buttons[x][y].value = val
	end

	def set_button_value_action(x, y, val)
		@buttons[x][y].value_action = val
	end

	def num_button_cols=(num_button_cols)
		pr_set_num_button_cols(num_button_cols)
		pr_reconstruct_children
	end

	def num_button_rows=(num_button_rows)
		pr_set_num_button_rows(num_button_rows)
		pr_reconstruct_children
	end

	def button_array_size
		Grrr::Point.new(@num_button_cols, @num_button_rows)
	end

	def button_array_size=(button_array_size)
		pr_set_num_button_cols(button_array_size.x)
		pr_set_num_button_rows(button_array_size.y)
		pr_reconstruct_children
	end

	def validate_button_array_size(button_array_size)
		new_num_button_cols = button_array_size[0]
		new_num_button_rows = button_array_size[1]
		if @num_cols % new_num_button_cols != 0
			raise "#{self.class} width (#@num_cols) must be divisable by number of button columns (#{new_num_button_cols})"
		end
		if @num_rows % new_num_button_rows != 0
			raise "#{self.class} height (#@num_rows) must be divisable by number of button rows (#{new_num_button_rows})"
		end
	end

	def num_buttons
		@num_button_cols * @num_button_rows
	end

	def button_width
		@num_cols / @num_button_cols
	end

	def button_height
		@num_rows / @num_button_rows
	end

	def is_lit_at?(point)
		validate_contains_point(point)
		@container_view.is_lit_at?(point)
	end

	def flash_button(x, y, delay)
		@buttons[x][y].flash(delay)
	end

	def flash_view(delay)
		pr_buttons_do do |button, x, y|
			button.flash(delay)
		end
	end

	def flash_points(points, delay)
		raise "not implemented for #{self.class}"
	end

	def pr_buttons_do
		if block_given?
			@num_button_cols.times do |x|
				@num_button_rows.times do |y|
					yield(@buttons[x][y], x, y)
				end
			end
		end
	end

	def pr_set_num_button_cols(num_button_cols)
		if @num_cols % num_button_cols == 0
			@num_button_cols = num_button_cols
		else
			raise "#{self.class} width (#@num_cols) must be divisable by number of button columns (#{num_button_cols})"
		end
	end

	def pr_set_num_button_rows(num_button_rows)
		if @num_rows % num_button_rows == 0
			@num_button_rows = num_button_rows
		else
			raise "#{self.class} height (#@num_rows) must be divisable by number of button rows (#{num_button_rows})"
		end
	end

	def pr_reconstruct_children
		release_all

		pr_do_then_refresh_changed_leds do
			@container_view.pr_remove_all_children(true)
			@buttons = Array.fill2d(@num_button_cols, @num_button_rows) do |x, y|
				button = Grrr::Button.new_detached(button_width, button_height)
				button.coupled = @coupled
				button.behavior = @behavior
				pr_add_actions(button, x, y)
				@container_view.pr_add_child_no_flash(button, Grrr::Point.new(x*button_width, y*button_height))
				button
			end
		end
	end

	def pr_add_actions(button, x, y)
		button.button_pressed_action = lambda { |view|
			@button_pressed_action.call(self, x, y) if @button_pressed_action
		}
		button.button_released_action = lambda { |view|
			@button_released_action.call(self, x, y) if @button_released_action
		}
		button.action = lambda { |view, value|
			@button_value_changed_action.call(self, x, y, value) if @button_value_changed_action
			do_action
		}
	end
end
