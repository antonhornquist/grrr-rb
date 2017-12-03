class Grrr::MultiToggleView < Grrr::View
	attr_accessor :toggle_pressed_action
	attr_accessor :toggle_released_action
	attr_accessor :toggle_value_pressed_action
	attr_accessor :toggle_range_pressed_action
	attr_accessor :toggle_value_changed_action
	attr_reader :num_toggles
	attr_reader :orientation
	attr_reader :thumb_width
	attr_reader :thumb_height

	def initialize(parent, origin, num_cols=nil, num_rows=nil, orientation=:vertical, enabled=true, coupled=true, nillable=false)
		super(nil, nil, num_cols, num_rows, enabled)

		@toggle_pressed_action = nil
		@toggle_value_pressed_action = nil
		@toggle_value_changed_action = nil
		@thumb_width = nil
		@thumb_height = nil
		@values_are_inverted = nil

		@orientation = orientation
		@coupled = coupled
		@nillable = nillable
		pr_set_num_toggles_defaults

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

		first_toggle = @toggles.first
		@filled = first_toggle.is_filled?
		@values_are_inverted = first_toggle.values_are_inverted?
		@thumb_width = first_toggle.thumb_width
		@thumb_height = first_toggle.thumb_height

		# view has to be added to parent after class-specific properties
		# have been initialized, otherwise it is not properly refreshed
		validate_parent_origin_and_add_to_parent(parent, origin)
	end

	def self.new_detached(num_cols=nil, num_rows=nil, orientation=:vertical, enabled=true, coupled=true, nillable=false)
		new(nil, nil, num_cols, num_rows, orientation, enabled, coupled, nillable)
	end

	def self.new_decoupled(parent, origin, num_cols=nil, num_rows=nil, orientation=:vertical, enabled=true, nillable=false)
		new(parent, origin, num_cols, num_rows, orientation, enabled, false, nillable)
	end

	def orientation=(orientation)
		@orientation = orientation
		pr_set_num_toggles_defaults
		pr_reconstruct_children
	end

	def is_coupled?
		@coupled
	end

	def coupled=(coupled)
		@toggles.each { |toggle| toggle.coupled = coupled }
		@coupled = coupled
	end

	def is_nillable?
		@nillable
	end

	def nillable=(nillable)
		@toggles.each { |toggle| toggle.nillable = nillable }
		@nillable = nillable
	end

	def is_filled?
		@filled
	end

	def filled=(filled)
		@toggles.each { |toggle| toggle.filled = filled }
		@filled = filled
	end

	def values_are_inverted?
		@values_are_inverted
	end

	def values_are_inverted=(values_are_inverted)
		@toggles.each { |toggle| toggle.values_are_inverted = values_are_inverted }
		@values_are_inverted=values_are_inverted
	end

	def thumb_size
		[@thumb_width, @thumb_height]
	end

	def thumb_width=(thumb_width)
		@toggles.each { |toggle| toggle.thumb_width = thumb_width }
		@thumb_width = @toggles.first.thumb_width
	end

	def thumb_height=(thumb_height)
		@toggles.each { |toggle| toggle.thumb_height = thumb_height }
		@thumb_height = @toggles.first.thumb_height
	end

	def thumb_size=(thumb_size)
		@toggles.each { |toggle| toggle.thumb_size = thumb_size }
		@thumb_width = @toggles.first.thumb_width
		@thumb_height = @toggles.first.thumb_height
	end

	def value
		@toggles.collect { |toggle| toggle.value }
	end

	def value=(val)
		validate_value(val)
		@num_toggles.times do |i|
			@toggles[i].value = val[i]
		end
	end

	def value_action=(val)
		validate_value(val)
		num_toggle_values_changed = 0
		@num_toggles.times do |i|
			new_toggle_value = val[i]
			if toggle_value(i) != new_toggle_value
				set_toggle_value(i, new_toggle_value)
				@toggle_value_changed_action.call(self, i, new_toggle_value) if @toggle_value_changed_action
				num_toggle_values_changed = num_toggle_values_changed + 1
			end
		end
		if num_toggle_values_changed > 0
			do_action
		end
	end

	def validate_value(val)
		raise "array must be of size #{@num_toggles}" if val.length != @num_toggles
		@num_toggles.times do |i|
			@toggles[i].validate_value(val[i])
		end
	end

	def maximum_toggle_value
		@toggles.first.maximum_value
	end

	def toggle_value(i)
		@toggles[i].value
	end

	def set_toggle_value(i, val)
		@toggles[i].value = val
	end

	def set_toggle_value_action(i, val)
		@toggles[i].value_action = val
	end

	def num_toggles=(num_toggles)
		validate_num_toggles(num_toggles)
		@num_toggles = num_toggles
		pr_reconstruct_children
	end

	def validate_num_toggles(num_toggles)
		if not is_valid_num_toggles?(num_toggles)
			case @orientation
				when :vertical
					raise "#{self.class} width (#{@num_cols}) must be divisable by number of toggles (#{num_toggles})"
				when :horizontal
					raise "#{self.class} height (#{@num_rows}) must be divisable by number of toggles (#{num_toggles})"
			end
		end
	end

	def is_valid_num_toggles?(num_toggles)
		(@orientation == :vertical ? @num_cols : @num_rows) % num_toggles == 0
	end

	def toggle_width
		case @orientation
			when :vertical
				@num_cols / @num_toggles
			when :horizontal
				@num_cols
		end
	end

	def toggle_height
		case @orientation
			when :vertical
				@num_rows
			when :horizontal
				@num_rows / @num_toggles
		end
	end

	def is_lit_at?(point)
		validate_contains_point(point)
		@container_view.is_lit_at?(point)
	end

	def flash_toggle(i, delay)
		@toggles[i].flash(delay)
	end

	def flash_view(delay)
		num_toggles.each { |i|
			@toggles[i].flash(delay)
		}
	end

	def flash_points(points, delay)
		raise "not implemented for multi_toggle_view"
	end

	def pr_reconstruct_children
		release_all

		pr_do_then_refresh_changed_leds do
			@container_view.pr_remove_all_children(true)
			@toggles = Array.fill(@num_toggles) do |i|
				toggle = Grrr::Toggle.new_detached(toggle_width, toggle_height, true, @coupled, @nillable, @orientation)
				if @values_are_inverted
					toggle.values_are_inverted = @values_are_inverted
				end
				if thumb_size != [nil, nil]
					if toggle.is_valid_thumb_size?(thumb_size)
						toggle.thumb_size = thumb_size
					else
						self.thumb_size_(toggle.thumb_size)
					end
				end
	
				position = if @orientation == :vertical
					Grrr::Point.new(i*toggle_width, 0)
				else
					Grrr::Point.new(0, i*toggle_height)
				end
	
				pr_add_actions(toggle, i)
				@container_view.pr_add_child_no_flash(toggle, position)
				toggle
			end
		end
	end

	def pr_add_actions(toggle, index)
		toggle.toggle_pressed_action = lambda { |view|
			@toggle_pressed_action.call(self, index) if @toggle_pressed_action
		}
		toggle.toggle_released_action = lambda { |view|
			@toggle_released_action.call(self, index) if @toggle_released_action
		}
		toggle.toggle_value_pressed_action = lambda { |view, affected_value|
			@toggle_value_pressed_action.call(self, index, affected_value) if @toggle_value_pressed_action
		}
		toggle.toggle_range_pressed_action = lambda { |view, range|
			@toggle_range_pressed_action.call(self, index, range) if @toggle_range_pressed_action
		}
		toggle.action = lambda { |view, value|
			@toggle_value_changed_action.call(self, index, value) if @toggle_value_changed_action
			do_action
		}
	end

	def pr_set_num_toggles_defaults
		@num_toggles = (@orientation == :vertical) ? @num_cols : @num_rows
	end
end
