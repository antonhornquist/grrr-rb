class Grrr::AbstractRangeToggle < Grrr::AbstractToggle
	def initialize(parent, origin, num_cols=nil, num_rows=nil, enabled=true, coupled=true, nillable=false)
		super(parent, origin, num_cols, num_rows, enabled, coupled, nillable)

		@value = [0, 0]

		@is_lit_at_func = lambda { |point|
			if @value
				val = value_at(point)
				# @value[0] <= val and val <= @value[1]
				value_within_range?(val)
			else
				false
			end != @led_inverted[point.x][point.y]
		}

		@view_button_state_changed_action = lambda { |point, pressed|
			affected_value = value_at(point)
			if pressed
				@values_pressed << affected_value
				range = [min_value_pressed, max_value_pressed]
				@previous_range = @value
				if @value != range
					if is_coupled?
						self.value_action=(range)
					end
					@toggle_range_defined_action.call(self, range) if @toggle_range_defined_action
				end
			else
				@values_pressed.delete(affected_value)
				if is_nillable? and no_value_pressed? and affected_value == lo and affected_value == hi and @previous_range == [affected_value, affected_value]
					self.value_action=(nil)
				end
			end
		}
	end

	def lo
		@value[0]
	end

	def lo=(lo)
		self.value=([lo, @value[1]])
	end

	def active_lo=(lo)
		self.value_action=([lo, @value[1]])
	end

	def hi
		@value[1]
	end

	def hi=(hi)
		self.value=([@value[0], hi])
	end

	def active_hi=(hi)
		self.value_action=([@value[0], hi])
	end

	def range
		[@value[1]-@value[0]]
	end

	def range=(range)
		self.value=([@value[0], @value[0]+range])
	end

	def active_range=(hi)
		self.value_action=([@value[0], @value[0]+range])
	end

	def set_span(lo, hi)
		self.value=([lo, hi])
	end

	def set_span_active(lo, hi)
		self.value_action=([lo, hi])
	end

	def value_within_range?(val)
		@value[0] <= val and val <= @value[1]
	end

	def flash_range(ms=nil)
		flash_points(to_points.select { |point| value_within_range?(value_at(point)) }, ms)
	end

	def flash_lo(ms=nil)
		flash_points(to_points.select { |point| lo == value_at(point) }, ms) # TODO: implement value_to_point(val) and simplify
	end

	def flash_hi(ms=nil)
		flash_points(to_points.select { |point| hi == value_at(point) }, ms) # TODO: implement value_to_point(val) and simplify
	end

	def validate_value(val)
		unless (is_nillable? and val == nil) or (val.respond_to? :at and (0..maximum_value).include?(val[0]) and (0..maximum_value).include?(val[1]))
			raise "value must be #{is_nillable? ? "nil or ":""}an array [lo, hi] of two integers between 0 and #{maximum_value}."
		end

		if val.respond_to? :at and val[0] > val[1]
			raise "supplied lo integer must be equal to or less than the hi integer."
		end
	end
end
