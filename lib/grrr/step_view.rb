class Grrr::StepView < Grrr::MultiButtonView
	attr_accessor :step_pressed_action
	attr_accessor :step_released_action
	attr_accessor :step_value_changed_action
	attr_reader :playhead

	def initialize(parent, origin, num_cols=nil, num_rows=nil, enabled=true, coupled=true)
		super(parent, origin, num_cols, num_rows, enabled, false, :toggle)

		@step_pressed_action = nil
		@step_released_action = nil
		@step_value_changed_action = nil
		@step_view_is_coupled = coupled
		@steps = Array.fill(num_steps, false)
		@button_pressed_action = lambda { |view, x, y|
			index = pr_xy_to_index(x, y)
			if @step_view_is_coupled
				set_step_value_action(index, !step_value(index))
			end
			@step_pressed_action.call(self, index) if @step_pressed_action
		}
		@button_released_action = lambda { |view, x, y|
			@step_released_action.call(self, pr_xy_to_index(x, y)) if @step_released_action
		}
	end

	def self.new_detached(num_cols=nil, num_rows=nil, enabled=true, coupled=true)
		new(nil, nil, num_cols, num_rows, enabled, coupled)
	end

	def self.new_decoupled(parent, origin, num_cols=nil, num_rows=nil, enabled=true)
		new(parent, origin, num_cols, num_rows, enabled, false)
	end

	def step_is_pressed?(index)
		x, y = *pr_index_to_xy(index)
		button_is_pressed?(x, y)
	end

	def step_is_released?(index)
		x, y = *pr_index_to_xy(index)
		button_is_released?(x, y)
	end

	def value
		@steps.dup
	end

	def value=(val)
		validate_value(val)
		num_steps.times { |index| set_step_value(index, val[index]) }
	end

	def value_action=(val)
		validate_value(val)
		num_step_values_changed = 0
		num_steps.times do |index|
			new_step_value = val[index]
			if step_value(index) != new_step_value
				set_step_value(index, new_step_value)
				@step_value_changed_action.call(self, index, new_step_value) if @step_value_changed_action
				num_step_values_changed = num_step_values_changed + 1
			end
		end
		if num_step_values_changed > 0
			do_action
		end
	end

	def validate_value(val)
		if val.size != num_steps
			raise ("value must be a 1-dimensional array of %d values" % [num_steps])
		end
	end

	def steps_pressed
		buttons_pressed.collect do |button|
			pr_xy_to_index(button.x, button.y)
		end
	end

	def step_value(index)
		@steps[index]
	end

	def flash_step(index, delay)
		x, y = *pr_index_to_xy(index)
		flash_button(x, y, delay)
	end

	def set_step_value(index, val)
		@steps[index] = val
		if pr_button_value_by_step_index(index) != (val || (@playhead == index))
			pr_set_button_value_by_step_index(index, val)
		end
	end

	def set_step_value_action(index, val)
		set_step_value(index, val)
		@step_value_changed_action.call(self, index, val) if @step_value_changed_action
		do_action
	end

	def num_steps
		num_buttons
	end

	def clear
		self.value=(Array.fill(num_steps) { false })
	end

	def clear_action
		self.value_action=(Array.fill(num_steps) { false })
	end

	def fill
		self.value=(Array.fill(num_steps) { true })
	end

	def fill_action
		self.value_action=(Array.fill(num_steps) { true })
	end

	def playhead=(index)
		previous_playhead_value = @playhead
		@playhead = index

		if @playhead
			if step_value(@playhead)
				flash_step(@playhead, 100)
			else
				pr_set_button_value_by_step_index(@playhead, true)
			end
			if previous_playhead_value
				pr_refresh_step(previous_playhead_value)
			end
		else
			if previous_playhead_value.notNil
				pr_refresh_step(previous_playhead_value)
			end
		end
	end

	def pr_refresh_step(index)
		x, y = *pr_index_to_xy(index)
		step_should_be_lit = step_value(index) || (index == @playhead)

		if button_value(x, y) != step_should_be_lit
			set_button_value(x, y, step_should_be_lit)
		end
	end

	def pr_xy_to_index(x, y)
		x + (y * num_button_cols)
	end

	def pr_index_to_xy(index)
		[index.to_i % num_button_cols, index.to_i / num_button_cols]
	end

	def pr_button_value_by_step_index(index)
		x, y = *pr_index_to_xy(index)
		button_value(x, y)
	end

	def pr_set_button_value_by_step_index(index, val)
		x, y = *pr_index_to_xy(index)
		set_button_value(x, y, val)
	end
end
