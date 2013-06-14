class Grrr::AreaView < Grrr::View
	attr_accessor :coupled, :area_set_action
	def initialize(parent, origin, num_cols=nil, num_rows=nil, enabled=true, coupled=true)
		super(parent, origin, num_cols, num_rows, enabled)
		@coupled = coupled
		@is_lit_at_func = lambda { |point|
			if @topleft and @bottomright
				(@topleft.x..@bottomright.x).include?(point.x) and (@topleft.y..@bottomright.y).include?(point.y)
			else
				false
			end
		}
		@view_button_state_changed_action = lambda { |point, pressed|
			if pressed
				old_topleft = @topleft
				old_bottomright = @bottomright
				@topleft = Point.new(leftmost_col_pressed, topmost_row_pressed)
				@bottomright = Point.new(rightmost_col_pressed, bottommost_row_pressed)
				if old_topleft != @topleft or old_bottomright != @bottomright
					do_action
					refresh
				end
			end
		}
	end

	def do_action
		@area_set_action.call(self, self.value) if @area_set_action
	end

	def value
		[@topleft, @bottomright]
	end

	def value=(val)
		@topleft = val[0]
		@bottomright = val[1]
	end

	def value_action=(val)
		self.value=(val)
		do_action
	end
end
