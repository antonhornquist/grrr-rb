class Grrr::MultiButtonView < Grrr::ContainerView
	attr_accessor :button_pressed_action
	attr_accessor :button_released_action
	attr_accessor :button_value_changed_action
	attr_reader :button_array_size
	attr_reader :behavior

	def initialize(parent, origin, num_cols=nil, num_rows=nil, enabled=true, coupled=true, behavior=:toggle)
		super(nil, nil, num_cols, num_rows, enabled, true)
		@coupled = coupled
		@behavior = behavior
		@button_array_size = [@num_cols, @num_rows]

		@acts_as_view = true

		pr_reconstruct_children

		# view has to be added to parent after class-specific properties
		# have been initialized, otherwise it is not properly refreshed
		validate_parent_origin_and_add_to_parent(parent, origin)
	end

	def self.new_detached(num_cols=nil, num_rows=nil, enabled=true, coupled=true, behavior=:toggle)
		new(nil, nil, num_cols, num_rows, enabled, coupled, behavior)
	end

	def self.new_disabled(parent, origin, num_cols=nil, num_rows=nil, coupled=true, behavior=:toggle)
		new(parent, origin, num_cols, num_rows, false, coupled, behavior)
	end

	def self.new_decoupled(parent, origin, num_cols=nil, num_rows=nil, enabled=true, behavior=:toggle)
		new(parent, origin, num_cols, num_rows, enabled, false, behavior)
	end

	def is_coupled?
		@coupled
	end

	def coupled=(coupled)
		@children.each { |child| child.coupled = coupled }
		@coupled = coupled
	end

	def behavior=(behavior)
		@children.each { |child| child.behavior = behavior }
		@behavior = behavior
	end

	def button_is_pressed?(x, y)
		@buttons[x][y].is_pressed?
	end

	def button_is_released?(x, y)
		@buttons[x][y].is_released?
	end

	def clear
		self.value=(Array.fill2d(num_button_cols, num_button_rows) { false })
	end

	def clear_action
		self.value_action=(Array.fill2d(num_button_cols, num_button_rows) { false })
	end

	def fill
		self.value=(Array.fill2d(num_button_cols, num_button_rows) { true })
	end

	def fill_action
		self.value_action=(Array.fill2d(num_button_cols, num_button_rows) { true })
	end

	def value
		@buttons.collect { |row| row.collect { |button| button.value } }
	end

	def value=(val)
		validate_value(val)
		num_button_cols.times do |x|
			num_button_rows.times do |y|
				@buttons[x][y].value = val[x][y]
			end
		end
	end

	def value_action=(val)
		validate_value(val)
		num_button_values_changed = 0
		num_button_cols.times do |x|
			num_button_rows.times do |y|
				button = @buttons[x][y]
				if button.value != val[x][y] then
					button.value = val[x][y]
					@button_value_changed_action.call(self, x, y, button.value) if @button_value_changed_action
					num_button_values_changed = num_button_values_changed + 1
				end
			end
		end
		if num_button_values_changed > 0
			do_action
		end
	end

	def validate_value(val)
		if not (val.size == num_button_cols and val.all? { |row| row.size == num_button_rows })
			raise "value must be a 2-dimensional array of #{num_button_cols}x#{num_button_rows} values"
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

	def button_array_size=(button_array_size)
		validate_button_array_size(button_array_size)
		@button_array_size = button_array_size
		pr_reconstruct_children
	end

	def validate_button_array_size(button_array_size)
		new_num_button_cols = button_array_size[0]
		new_num_button_rows = button_array_size[1]
		if @num_cols % new_num_button_cols != 0
			raise "#{self.class} width (#@num_cols) must be divisable by number of button columns (#{new_num_button_cols})"
		end
		if @num_rows % new_num_button_rows != 0
			raise "#{self.class} height (#@num_rows) must be divisable by number of button columns (#{new_num_button_rows})"
		end
	end

	def num_button_cols
		@button_array_size[0]
	end

	def num_button_rows
		@button_array_size[1]
	end

	def num_buttons
		num_button_cols * num_button_rows
	end

	def button_width
		@num_cols / num_button_cols
	end

	def button_height
		@num_rows / num_button_rows
	end

	def pr_reconstruct_children
		release_all
		pr_remove_all_children(true)

		@buttons = Array.fill2d(num_button_cols, num_button_rows) do |x, y|
			button = Button.new_detached(button_width, button_height)
			button.coupled = @coupled
			pr_add_actions(button, x, y)
			pr_add_child_no_flash(button, Point.new(x*button_width, y*button_height))
			button
		end
	end

	def pr_add_actions(button, x, y)
		button.button_pressed_action = lambda { |button|
			@button_pressed_action.call(self, x, y) if @button_pressed_action
		}
		button.button_released_action = lambda { |button|
			@button_released_action.call(self, x, y) if @button_released_action
		}
		button.action = lambda { |button, value|
			@button_value_changed_action.call(self, x, y, value) if @button_value_changed_action
			do_action
		}
	end
end
