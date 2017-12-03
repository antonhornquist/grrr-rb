class Grrr::Toggle < Grrr::AbstractToggle
	attr_accessor :toggle_pressed_action
	attr_accessor :toggle_released_action
	attr_accessor :toggle_value_pressed_action
	attr_accessor :toggle_range_pressed_action

	def initialize(parent, origin, num_cols=nil, num_rows=nil, enabled=true, coupled=true, nillable=false, orientation=:vertical)
		super(num_cols, num_rows, enabled, coupled, nillable, orientation)

		@toggle_pressed_action = nil
		@toggle_released_action = nil
		@toggle_value_pressed_action = nil
		@toggle_range_pressed_action = nil
		@saved_range = nil

		@value = 0
		@filled = false

		@is_lit_at_func = lambda { |point|
			if @value.nil?
				false
			else
				value_at_point = value_at(point)
				if is_filled?
					value_at_point <= @value
				else
					value_at_point == @value
				end
			end
		}

		@view_button_state_changed_action = lambda { |point, pressed|
			affected_value = value_at(point)
			if pr_view_button_state_change_affected_values_pressed?
				if pressed
					@values_pressed << affected_value
					local_num_values_pressed = num_values_pressed
		
					if is_coupled?
						if is_nillable? and affected_value == @value
							self.value_action=(nil)
						else
							self.value_action=(affected_value)
						end
					end
		
					@toggle_value_pressed_action.call(self, affected_value) if @toggle_value_pressed_action
		
					if local_num_values_pressed == 1
						@toggle_pressed_action.call(self) if @toggle_pressed_action
					end
		
					if local_num_values_pressed > 1
						range = [min_value_pressed, max_value_pressed]
						if @saved_range != range
							@toggle_range_pressed_action.call(self, range) if @toggle_range_pressed_action
							@saved_range = range
						end
					end
				else
					@values_pressed.delete(affected_value)
					if no_value_pressed?
						@toggle_released_action.call(self) if @toggle_released_action
					end
				end
			end
		}

		# view has to be added to parent after class-specific properties
		# have been initialized, otherwise it is not properly refreshed
		validate_parent_origin_and_add_to_parent(parent, origin)
	end

	def self.new_decoupled(parent, origin, num_cols=nil, num_rows=nil, enabled=true, nillable=false, orientation=:vertical)
		new(parent, origin, num_cols, num_rows, enabled, false, nillable, orientation)
	end

	def self.new_detached(num_cols=nil, num_rows=nil, enabled=true, coupled=true, nillable=false, orientation=:vertical)
		new(nil, nil, num_cols, num_rows, enabled, coupled, nillable, orientation)
	end

	def self.new_nillable(parent, origin, num_cols=nil, num_rows=nil, enabled=true, coupled=true, orientation=:vertical)
		new(parent, origin, num_cols, num_rows, enabled, coupled, true, orientation)
	end

	def is_filled?
		@filled
	end

	def filled=(filled)
		@filled = filled
		refresh if @enabled
	end

	def nillable=(nillable)
		@nillable = nillable

		if @nillable == false and @value == nil
			self.value_action=(0)
		end
	end

	def validate_value(value)
		unless (is_nillable? and value == nil) or (0..maximum_value).include?(value)
			raise "value must be #{@nillable ? "nil or ":""}an integer between 0 and #{maximum_value}"
		end
	end

	def flash(delay=nil)
		points_to_flash = to_points.select { |point|
			if is_filled?
				value_at(point) <= @value
			else
				value_at(point) == @value
			end
		}
		flash_points(points_to_flash, delay)
	end

	def flash_toggle_value(value, delay=nil)
		points_to_flash = to_points.select { |point|
			value_at(point) == value
		}
		flash_points(points_to_flash, delay)
	end

	def pr_view_button_state_change_affected_values_pressed?
		@values_pressed.size != @points_pressed.collect { |point| value_at(point) }.uniq.size
	end
end
