class Grrr::StepView < Grrr::View
	PLAYHEAD_FLASH_DELAY_WHEN_LIT = 100

	attr_accessor :step_pressed_action
	attr_accessor :step_released_action
	attr_accessor :step_value_changed_action
	attr_reader :playhead

	def initialize(parent, origin, num_cols=nil, num_rows=nil, enabled=true, coupled=true)
		super(nil, nil, num_cols, num_rows, enabled)

		@step_pressed_action = nil
		@step_released_action = nil
		@step_value_changed_action = nil
		@playhead = nil
		@coupled = coupled

		@multi_button_view = Grrr::MultiButtonView.new_detached(@num_cols, @num_rows, true, false, :toggle)
		@multi_button_view.add_action(lambda { |originating_button, point, on|
			if has_view_led_refreshed_action?
				view_led_refreshed_action.call(self, point, on)
			end
		}, :view_led_refreshed_action)
		add_action(lambda { |point, pressed|
			@multi_button_view.handle_view_button_event(self, point, pressed)
		}, :view_button_state_changed_action)

		@multi_button_view.button_pressed_action = lambda { |view, x, y|
			index = pr_xy_to_index(x, y)
			if @coupled
				set_step_value_action(index, !step_value(index))
			end
			@step_pressed_action.call(self, index) if @step_pressed_action
		}
		@multi_button_view.button_released_action = lambda { |view, x, y|
			@step_released_action.call(self, pr_xy_to_index(x, y)) if @step_released_action
		}

		@steps = Array.fill(num_steps, false)

		# view has to be added to parent after class-specific properties
		# have been initialized, otherwise it is not properly refreshed
		validate_parent_origin_and_add_to_parent(parent, origin)
	end

	def self.new_detached(num_cols=nil, num_rows=nil, enabled=true, coupled=true)
		new(nil, nil, num_cols, num_rows, enabled, coupled)
	end

	def self.new_decoupled(parent, origin, num_cols=nil, num_rows=nil, enabled=true)
		new(parent, origin, num_cols, num_rows, enabled, false)
	end

	def is_lit_at?(point)
		validate_contains_point(point)
		@multi_button_view.is_lit_at?(point)
	end

	def step_is_pressed?(index)
		point = pr_index_to_xy(index)
		@multi_button_view.button_is_pressed?(point.x, point.y)
	end

	def step_is_released?(index)
		point = pr_index_to_xy(index)
		@multi_button_view.button_is_released?(point.x, point.y)
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
		@multi_button_view.buttons_pressed.collect do |pos|
			pr_xy_to_index(pos.x, pos.y)
		end
	end

	def step_value(index)
		@steps[index]
	end

	def flash_step(index, delay)
		point = pr_index_to_xy(index)
		@multi_button_view.flash_button(point.x, point.y, delay)
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
		@multi_button_view.num_buttons
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
			if step_value(@playhead) or previous_playhead_value == @playhead
				flash_step(@playhead, PLAYHEAD_FLASH_DELAY_WHEN_LIT)
			else
				pr_set_button_value_by_step_index(@playhead, true)
			end
		end
		if previous_playhead_value != nil and previous_playhead_value != @playhead
			pr_refresh_step(previous_playhead_value)
		end
	end

	def pr_refresh_step(index)
		point = pr_index_to_xy(index)
		step_should_be_lit = step_value(index) || (index == @playhead)

		if @multi_button_view.button_value(point.x, point.y) != step_should_be_lit
			@multi_button_view.set_button_value(point.x, point.y, step_should_be_lit)
		end
	end

	def pr_xy_to_index(x, y)
		x + (y * @multi_button_view.num_button_cols)
	end

	def pr_index_to_xy(index)
		Grrr::Point.new(index.to_i % @multi_button_view.num_button_cols, index.to_i / @multi_button_view.num_button_cols)
	end

	def pr_button_value_by_step_index(index)
		point = pr_index_to_xy(index)
		@multi_button_view.button_value(point.x, point.y)
	end

	def pr_set_button_value_by_step_index(index, val)
		point = pr_index_to_xy(index)
		@multi_button_view.set_button_value(point.x, point.y, val)
	end
end
